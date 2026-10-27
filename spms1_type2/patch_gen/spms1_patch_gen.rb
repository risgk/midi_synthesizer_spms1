# Writes what the sketch reads from spms1_patch.yaml: spms1/spms1_patch.rb and
# spms1/spms1_default_patch.h whole, the parts of spms1_editor.html, spms1_patching.md,
# spms1_patching.ja.md and spms1/spms1_main.rb between their "patch_gen" markers.
#
#   ruby patch_gen/spms1_patch_gen.rb [--check | --renumber]
#
# --check writes nothing, and exits with 1 if a file is not what it would write. --renumber first
# numbers every list of spms1_patch.yaml again in its order, as the YAML says they are, for after
# something was added or moved, then writes the rest. Needs CRuby only
# (YAML and JSON are in its standard library). Run from anywhere.

require 'yaml'
require 'json'

# The Markdown documents are UTF-8 whatever the locale (Windows', or a CI runner's) says.
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

DIR = File.expand_path('..', __dir__)
SPEC_FILE = File.join(DIR, 'spms1_patch.yaml')

NRPN_ACTIVE_MODULE_BASE = 0
NRPN_INPUT_BASE         = 128
NRPN_PARAM_SOURCE_BASE  = 256
NRPN_CC_BASE            = 384
NRPN_VALUE_BASE         = 512

# A parameter source of 127 is the parameter's own control slot, which is off the bus: the bus
# carries the outputs, the constants, the notes and the controllers in 0-126, and each
# parameter's control slot sits at 128 + its entry, where only the parameter reads it.
SIGNAL_OWN      = 127
PARAM_SLOT_BASE = 128
# The size of the `signals` array, as spms1_main.rb makes it: the smoothed copies of the controller
# slots go at its top.
SIGNALS_SIZE = 512
# The module classes with a smooth_parameters, which the main loop calls once every 16 samples.
SMOOTHED_EVERY_16 = %w[Pitch LFO Osc Filter Chorus Delay].freeze

def fail_spec(message)
  abort "spms1_patch_gen.rb: spms1_patch.yaml: #{message}"
end

# The spec, read and checked: every number unique, every key it names defined.
class Spec
  attr_reader :modules, :signals, :inputs, :inputs_in_list_order, :controls, :controls_in_list_order, :default_order,
              :saved_patch_version

  def initialize(yaml)
    @modules  = yaml.fetch('modules')
    @signals  = yaml.fetch('signals')
    # The list's order is the editor's: an input or a control goes next to its module's others
    # there, though its entry is appended. Everything else takes them by entry.
    @inputs_in_list_order = yaml.fetch('inputs')
    @inputs = @inputs_in_list_order.sort_by { |i| i['entry'] }
    @controls_in_list_order = yaml.fetch('controls')
    @controls = @controls_in_list_order.sort_by { |c| c['entry'] }
    @default_order = yaml.fetch('default_order')
    @saved_patch_version = yaml.fetch('saved_patch_version')
    @module = @modules.to_h { |m| [m['key'], m] }
    @control = @controls.to_h { |c| [full_key(c), c] }
    @signal = @signals.to_h { |s| [s['key'], s] }
    check
  end

  def module(key) = @module.fetch(key)
  def control(key) = @control.fetch(key)
  def signal(key) = @signal.fetch(key)

  FORMS = %w[rev inv rev_inv bipolar bipolar_inv sin cos lo hi neg mid pos].freeze

  # A module input's or control's own name, with its module's in front: OSC_1_PITCH_IN, OUTPUT_L.
  def full_key(item) = item['module'] ? "#{item['module']}_#{item['key']}" : item['key']

  def full_label(item, name = item['label']) = item['module'] ? "#{self.module(item['module'])['label']} #{name}" : name

  def params = @controls.reject { |c| c['controller'] }
  def controllers = @controls.select { |c| c['controller'] }
  def outputs_of(mod) = @signals.select { |s| s['output'] && s['module'] == mod['key'] }
  # The bus slots a controller control's CC fills; a parameter's control slot is its own, off the bus.
  def slots_of(control) = @signals.select { |s| s['control'] == full_key(control) }

  # Every controller's slots, the mod wheel's and the general controls', in id order.
  def controller_slots = @signals.select { |s| s['control'] }

  # Where the smoothed copies of the controller slots start, at the top of the array with each
  # controller's first smoothing stage above them.
  def smoothed_base = SIGNALS_SIZE - controller_slots.size - controllers.size

  def bipolar?(signal)
    return !!signal['bipolar'] unless signal['control'] && !signal.key?('bipolar')
    !!control(signal['control'])['bipolar']
  end

  def signal_label(signal, ja: false)
    label = (ja && signal['label_ja']) || signal['label'] || full_label(control(signal['control']))
    bipolar?(signal) ? "#{label} ±" : label
  end

  private

  def check
    unique = lambda do |what, list, field|
      seen = {}
      list.each do |item|
        value = item.fetch(field) { fail_spec("#{what} #{item.inspect} has no #{field}") }
        fail_spec("#{what} #{field} #{value} is used twice") if seen[value]
        seen[value] = true
      end
    end
    unique.call('module', @modules, 'id')
    unique.call('module', @modules, 'key')
    unique.call('signal', @signals, 'id')
    unique.call('signal', @signals, 'key')
    unique.call('input', @inputs, 'entry')
    unique.call('control', @controls, 'entry')
    unique.call('control', @controls.map { |c| { 'key' => full_key(c) } }, 'key')
    # Each list numbered in its order with no gaps (see the top of the YAML).
    in_order = lambda do |what, list, field, first|
      list.each_with_index do |item, n|
        fail_spec("#{what} #{item['key']} is #{field} #{item[field]}, not #{first + n}, its place in the list") unless item[field] == first + n
      end
    end
    in_order.call('module', @modules, 'id', 1)
    in_order.call('signal', @signals, 'id', 0)
    in_order.call('input', @inputs_in_list_order, 'entry', 0)
    in_order.call('control', @controls_in_list_order, 'entry', 0)
    fail_spec('module id 0 is MODULE_NONE') if @module.values.any? { |m| m['id'] == 0 }
    fail_spec('module ids are 1-127') if @modules.any? { |m| m['id'] > 127 }
    fail_spec("signal ids are 0-126, #{SIGNAL_OWN} being a parameter's own slot") if @signals.any? { |s| s['id'] >= SIGNAL_OWN }
    fail_spec('signal 0 must be NONE') unless @signals.any? { |s| s['id'] == 0 && s['key'] == 'NONE' }
    fail_spec('input entries are 0-127') if @inputs.any? { |i| i['entry'] > 127 }
    fail_spec('control entries are 0-127') if @controls.any? { |c| c['entry'] > 127 }
    @default_order.each { |k| self.module(k) rescue fail_spec("default_order names #{k}, no module") }
    @signals.each do |s|
      fail_spec("signal #{s['key']} names module #{s['module']}") if s['module'] && !@module[s['module']]
      fail_spec("signal #{s['key']} names control #{s['control']}") if s['control'] && !@control[s['control']]
      fail_spec("signal #{s['key']} is a parameter's control slot, which is off the bus") if s['control'] && !@control[s['control']]['controller']
      fail_spec("signal #{s['key']} has form #{s['form']}, none of #{FORMS.join(', ')}") if s['form'] && !FORMS.include?(s['form'])
      fail_spec("signal #{s['key']} has a form but no control") if s['form'] && !s['control']
    end
    (@inputs + @controls).each do |item|
      fail_spec("#{full_key(item)} names module #{item['module']}") if item['module'] && !@module[item['module']]
      fail_spec("#{full_key(item)} takes #{item['source']}, no signal") if item['source'] && !@signal[item['source']]
    end
    # Each key is its label in capitals with an underscore for each run of anything else, as
    # "Pitch Mod 1 Pol" is PITCH_MOD_1_POL, so that a key reads as what the editor shows. The sides
    # of the final output and the constants are named for what they are instead, and a controller's
    # plain slot, with no label of its own, takes its control's key, as checked below.
    (@modules + @inputs.select { |i| i['module'] } + @controls + @signals.select { |sig| sig['label'] && (sig['module'] || sig['control']) }).each do |item|
      want = item['label'].upcase.gsub(/[^A-Z0-9]+/, '_').delete_prefix('_').delete_suffix('_')
      fail_spec("#{@signals.include?(item) ? item['key'] : full_key(item)} is labeled #{item['label']}, so its key is #{want}") unless item['key'] == want
    end
    ids = controller_slots.map { |sig| sig['id'] }
    fail_spec('the controller slots are not one run of ids') unless ids == (ids.first..ids.last).to_a
    fail_spec('the smoothed controller slots run into the parameter slots') if smoothed_base <= PARAM_SLOT_BASE + params.map { |c| c['entry'] }.max
    @controls.each do |c|
      fail_spec("controller control #{full_key(c)} fills no slot") if c['controller'] && slots_of(c).empty?
      plain = slots_of(c).find { |s| !s['form'] }
      fail_spec("controller control #{full_key(c)} has forms but no unipolar plain slot, its key, first") if c['controller'] && slots_of(c).any? { |s| s['form'] } && (slots_of(c).first != plain || plain['key'] != full_key(c) || bipolar?(plain))
      fail_spec("control #{full_key(c)} has a CC but no value") if c['cc'].to_i != 0 && !c.key?('value')
      fail_spec("parameter #{full_key(c)} has no value") if !c['controller'] && !c.key?('value')
    end
  end
end

# Writes each item's number in the YAML as its place in its list: `id` from 0 on the bus and from 1
# for the modules, `entry` from 0 for the inputs and the controls. Only the number is touched, so
# the comments and the layout stay as they are.
def renumber_spec
  first = { 'modules' => 1, 'signals' => 0, 'inputs' => 0, 'controls' => 0 }
  field = { 'modules' => 'id', 'signals' => 'id', 'inputs' => 'entry', 'controls' => 'entry' }
  section = nil
  count = 0
  text = File.read(SPEC_FILE).lines.map do |line|
    if line =~ /^(\w+):/
      section = $1
      count = first[section] || 0
    end
    next line unless first.key?(section) && line.start_with?('  - {')
    number = count
    count += 1
    line.sub(/\b#{field[section]}: *\d+/) { "#{field[section]}: #{number}" }
  end.join
  File.write(SPEC_FILE, text)
end

renumber_spec if ARGV.include?('--renumber')
SPEC = Spec.new(YAML.load_file(SPEC_FILE))

# ---- spms1_patch.rb ----------------------------------------------------------------------------

def ruby_constants(pairs)
  width = pairs.map { |name, _| name.length }.max
  pairs.map { |name, value| "#{name.ljust(width)} = #{value}" }.join("\n")
end

def patch_rb
  s = SPEC
  out = []
  out << <<~RUBY
    # Generated from spms1_patch.yaml by patch_gen/spms1_patch_gen.rb. Do not edit; change the YAML
    # and run the generator.

    # Module ids, the values of NRPN category 0. MODULE_NONE ends the run order.
  RUBY
  out << ruby_constants([['MODULE_NONE', 0]] + s.modules.map { |m| ["MODULE_#{m['key']}", m['id']] })
  out << "\n\n# Slots of the signal bus, the values of NRPN categories 1 and 2.\n"
  out << ruby_constants(s.signals.map { |sig| ["SIGNAL_#{sig['key']}", sig['id']] })
  out << "\n\n# A parameter source of SIGNAL_OWN is the parameter's own control slot, at PARAM_SLOT_BASE + its\n"
  out << "# entry, off the bus: the slots below.\n"
  out << "SIGNAL_OWN      = #{SIGNAL_OWN}\nPARAM_SLOT_BASE = #{PARAM_SLOT_BASE}\n\n"
  out << ruby_constants(s.params.map { |c| ["SLOT_#{s.full_key(c)}", PARAM_SLOT_BASE + c['entry']] })
  first = s.controller_slots.first['id']
  out << "\n\n# The controller slots, the mod wheel's and the general controls', and where a smoothed copy of each\n"
  out << "# sits, off the bus at its slot + SMOOTHED_SLOT_OFFSET, with each controller's first smoothing\n"
  out << "# stage above them. A module input reads the copy (see spms1_main.rb).\n"
  out << ruby_constants([['CONTROLLER_SLOT_FIRST', first], ['CONTROLLER_SLOT_LAST', s.controller_slots.last['id']],
                         ['SMOOTHED_SLOT_OFFSET', s.smoothed_base - first]] +
                        s.controllers.each_with_index.map { |c, n| ["SMOOTHED_STAGE_1_#{s.full_key(c)}", s.smoothed_base + s.controller_slots.size + n] })
  out << "\n\n# NRPN parameter numbers: (category << 7) | LSB, where the MSB, 112 + category, picks a category\n# and the LSB an entry.\n"
  out << "#   0..127   the run order, the module of each slot\n# 128..255   what feeds each module input\n"
  out << "# 256..383   where each parameter's value comes from\n# 384..511   which CC fills each control slot\n"
  out << "# 512..639   the value of each parameter's control slot while it has no CC\n"
  out << "NRPN_ACTIVE_MODULE_BASE = #{NRPN_ACTIVE_MODULE_BASE}\n\n"
  out << ruby_constants(s.inputs.map { |i| ["NRPN_SOURCE_#{s.full_key(i)}", NRPN_INPUT_BASE + i['entry']] })
  out << "\n\n"
  out << ruby_constants(s.params.map { |c| ["NRPN_SOURCE_#{s.full_key(c)}", NRPN_PARAM_SOURCE_BASE + c['entry']] })
  out << "\n\n# A CC number of 0 means the control has no CC: a parameter's control slot then holds its NRPN_VALUE_*\n"
  out << "# below, whatever CC it had before, so a patch sets it alone, and a controller slot holds 0.0.\n"
  out << ruby_constants(s.controls.map { |c| ["NRPN_CC_#{s.full_key(c)}", NRPN_CC_BASE + c['entry']] })
  out << "\n\n# The value of each parameter's control slot while it has no CC, as a CC value.\n"
  out << ruby_constants(s.params.map { |c| ["NRPN_VALUE_#{s.full_key(c)}", NRPN_VALUE_BASE + c['entry']] })
  out << "\n\n# The constants of the bus, which nothing else ever writes. A slot not written here holds 0.0.\n"
  out << "def spms1_fill_constant_signals(signals)\n"
  consts = s.signals.select { |sig| sig.key?('value') && sig['value'] != 0.0 }
  width = consts.map { |sig| sig['key'].length }.max
  consts.each do |sig|
    out << "  signals[SIGNAL_#{sig['key']}]#{' ' * (width - sig['key'].length)} = #{sig['value'] == sig['value'].round(1) ? format('%4.1f', sig['value']) : sig['value']}\n"
  end
  out << "end\n\n"
  out << "# The default patch, written into the NRPN table, and the values its CCs power up at. Each\n"
  out << "# parameter's NRPN value is its power-up value too, which its slot holds while it has no CC.\n"
  out << "def spms1_write_default_patch(midi_ch)\n"
  s.default_order.each_with_index do |k, i|
    out << "  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + #{i}, MODULE_#{k})\n"
  end
  out << "\n"
  width = s.inputs.map { |i| s.full_key(i).length }.max
  s.inputs.each do |i|
    out << "  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_#{s.full_key(i).ljust(width)}, SIGNAL_#{i['source']})\n"
  end
  out << "\n"
  width = s.params.map { |c| s.full_key(c).length }.max
  s.params.each do |c|
    out << "  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_#{s.full_key(c).ljust(width)}, SIGNAL_#{c['source'] || 'OWN'})\n"
  end
  out << "\n"
  with_cc = s.controls.select { |c| c['cc'].to_i != 0 }
  width = with_cc.map { |c| s.full_key(c).length }.max
  with_cc.each do |c|
    out << "  C.set_midi_nrpn_value(midi_ch, NRPN_CC_#{s.full_key(c).ljust(width)}, #{c['cc']})\n"
  end
  out << "\n"
  width = s.params.map { |c| s.full_key(c).length }.max
  s.params.each do |c|
    out << "  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_#{s.full_key(c).ljust(width)}, #{c['value']})\n"
  end
  out << "\n"
  with_cc.each do |c|
    out << "  C.set_midi_cc_value(midi_ch, #{c['cc'].to_s.ljust(3)}, #{c['value'].to_s.ljust(3)}) # #{s.full_label(c)}\n"
  end
  out << "end\n"
  out.join
end

# ---- spms1_default_patch.h ---------------------------------------------------------------------

# Every number a saved patch is written in -- each module's id, each bus slot's, each input's and
# each control's entry, and which controls are controllers -- with saved_patch_version, as one
# FNV-1a hash of a line each, so that a sketch can tell a patch saved by one numbered otherwise.
# Names, labels, defaults and the rest a saved patch does not hold are left out: changing them
# keeps the patches saved.
def patch_spec_hash
  s = SPEC
  lines = ["saved_patch_version #{s.saved_patch_version}"]
  lines += s.modules.map { |m| "module #{m['key']} #{m['id']}" }
  lines += s.signals.map { |sig| "signal #{sig['key']} #{sig['id']}" }
  lines += s.inputs.map { |i| "input #{s.full_key(i)} #{i['entry']}" }
  lines += s.controls.map { |c| "control #{s.full_key(c)} #{c['entry']}#{c['controller'] ? ' controller' : ''}" }
  hash = 2166136261
  lines.join("\n").each_byte { |b| hash = ((hash ^ b) * 16777619) & 0xFFFFFFFF }
  hash
end

# The default patch again, as tables for spms1_midi_state.h, which writes it back when the reset
# NRPN arrives: the same writes as spms1_write_default_patch, in the same order, so that a reset
# leaves the tables as power-up does, the times the run order was written included.
def default_patch_h
  s = SPEC
  nrpn = []
  s.default_order.each_with_index { |k, i| nrpn << [NRPN_ACTIVE_MODULE_BASE + i, s.module(k)['id'], "Run order #{i}: #{s.module(k)['label']}"] }
  s.inputs.each { |i| nrpn << [NRPN_INPUT_BASE + i['entry'], s.signal(i['source'])['id'], "#{s.full_label(i)} <- #{i['source']}"] }
  s.params.each { |c| nrpn << [NRPN_PARAM_SOURCE_BASE + c['entry'], c['source'] ? s.signal(c['source'])['id'] : SIGNAL_OWN, "#{s.full_label(c)} <- #{c['source'] || 'OWN'}"] }
  with_cc = s.controls.select { |c| c['cc'].to_i != 0 }
  with_cc.each { |c| nrpn << [NRPN_CC_BASE + c['entry'], c['cc'], "#{s.full_label(c)} CC"] }
  s.params.each { |c| nrpn << [NRPN_VALUE_BASE + c['entry'], c['value'], "#{s.full_label(c)} value"] }
  out = []
  saved_cc = s.controls.reject { |c| c['performance'] }.map { |c| c['entry'] }
  out << <<~C
    /*
     * Generated from spms1_patch.yaml by patch_gen/spms1_patch_gen.rb. Do not edit; change the YAML
     * and run the generator.
     *
     * The default patch, as spms1_write_default_patch in spms1_patch.rb writes it at power-up: the
     * NRPN entries, then the values its CCs power up at. spms1_midi_state.h writes it back when the
     * reset NRPN arrives. And what a saved patch is checked against, and keeps of the CC values.
     */
    #ifndef SPMS1_DEFAULT_PATCH_H
    #define SPMS1_DEFAULT_PATCH_H

    #include <stdint.h>

    // The numbers of the patch and saved_patch_version, as one hash (see patch_spec_hash in
    // patch_gen): a saved patch with another is not loaded.
    #define SPMS1_PATCH_SPEC_HASH (0x#{format('%08X', patch_spec_hash)}u)

    // The category 3 entries -- the controls -- whose CCs' values a Save keeps: all but the
    // performance controls', whose CCs are saved at 0.
    static const uint8_t g_spms1_saved_cc_entries[] = {
    #{saved_cc.each_slice(16).map { |row| '  ' + row.join(', ') }.join(",\n")}
    };

    // NRPN parameter number (category << 7 | LSB), value
    static const uint16_t g_spms1_default_nrpn[][2] = {
  C
  nrpn.each { |n, v, label| out << "  {#{(n.to_s + ',').ljust(4)} #{v.to_s.rjust(3)}},  // #{label}\n" }
  out << "};\n\n// CC number, value\nstatic const uint8_t g_spms1_default_cc[][2] = {\n"
  with_cc.each { |c| out << "  {#{(c['cc'].to_s + ',').ljust(4)} #{c['value'].to_s.rjust(3)}},  // #{s.full_label(c)}\n" }
  out << "};\n\n#endif  // SPMS1_DEFAULT_PATCH_H\n"
  out.join
end

# ---- spms1_editor.html -------------------------------------------------------------------------

# The tables of the editor, as one object literal: plain data, which the editor turns into the
# structures it works with.
def editor_js
  s = SPEC
  spec = {
    modules: s.modules.map do |m|
      { key: m['key'], id: m['id'], label: m['label'],
        outs: s.outputs_of(m).map { |o| { sig: o['key'], label: o['output'] } } }
    end,
    inputs: s.inputs_in_list_order.map do |i|
      { entry: i['entry'], module: i['module'], key: i['key'], label: i['label'], source: i['source'] }
    end,
    controls: s.controls_in_list_order.map do |c|
      h = { entry: c['entry'], module: c['module'], key: c['key'], label: c['label'],
            bipolar: !!c['bipolar'], cc: c['cc'].to_i, value: c['value'], source: c['source'],
            controller: !!c['controller'], performance: !!c['performance'], hint: c['hint'], hintInputs: c['hint_inputs'],
            favorite: c['favorite'],
            slots: if c['controller']
                     s.slots_of(c).map { |sig| [sig['key'], sig['label'] || c['label'], s.bipolar?(sig), sig['form']].compact }
                   else
                     [[s.full_key(c), c['label'], !!c['bipolar']]]
                   end }
      h.compact
    end,
    # The editor labels outputs and control slots itself, from their module and control.
    signals: s.signals.map do |sig|
      label = sig['output'] || sig['control'] ? nil : sig['short'] || sig['label']
      { id: sig['id'], key: sig['key'], label: label }.compact
    end,
    defaultOrder: s.default_order,
    # SPMS1_PATCH_SPEC_HASH, which a SysEx carries, so that a sketch numbered otherwise ignores it.
    specHash: patch_spec_hash,
  }
  lines = ['  const SPEC = {']
  spec.each do |name, list|
    if list.is_a?(Integer)
      lines << "    #{name}: 0x#{format('%08X', list)},"
    elsif list.first.is_a?(String)
      lines << "    #{name}: #{JSON.generate(list)},"
    else
      lines << "    #{name}: ["
      list.each { |item| lines << "      #{JSON.generate(item)}," }
      lines << '    ],'
    end
  end
  lines << '  };'
  lines.join("\n") + "\n"
end

# ---- spms1_patching.md, spms1_patching.ja.md ---------------------------------------------------

# A Markdown table of `rows` (each a row's cells) in `columns` groups side by side, filled down
# each group in turn, with an empty column between groups. A '|' in a cell, as in a label that
# lists its choices, is escaped so that it does not end the cell.
def side_by_side(headers, rows, columns)
  rows = rows.map { |row| row.map { |cell| cell.to_s.gsub('|', '\\|') } }
  line = ->(groups, between) { '| ' + groups.map { |g| g.join(' | ') }.join(" | #{between}| ") + ' |' }
  per = (rows.length + columns - 1) / columns
  head = line.call([headers] * columns, '')
  rule = line.call([['-----'] + ['------'] * (headers.length - 1)] * columns, '- ')
  body = (0...per).map do |r|
    line.call((0...columns).map { |col| rows[col * per + r] || [''] * headers.length }, '')
  end
  [head, rule, *body].join("\n") + "\n"
end

def readme_tables(ja:)
  s = SPEC
  t = {}
  t['inputs'] = side_by_side(['CC#98', ja ? 'モジュール入力' : 'Module input'],
    s.inputs.map { |i| [i['entry'], s.full_label(i, (ja && i['name_ja']) || i['name'])] }, 2)
  t['params'] = side_by_side(['CC#98', ja ? 'パラメータ' : 'Parameter'],
    s.params.map { |c| [c['entry'], s.full_label(c)] }, 3)
  sep = ja ? '、' : ', '
  rows = s.controllers.map do |c|
    "| #{c['entry']} | #{s.full_label(c)} | #{s.slots_of(c).map { |sig| sig['label'] || s.full_label(c) }.join(sep)} |"
  end
  t['controllers'] = (["| CC#98 | #{ja ? 'CC の割り当て先' : 'CC for'} | #{ja ? '埋めるスロット' : 'Fills'} |",
                    '| ----- | ------ | ----- |'] + rows).join("\n") + "\n"
  rows = ["| 0 | #{ja ? 'なし（実行順の終端）' : 'None (ends the run order)'} |"] +
         s.modules.map { |m| "| #{m['id']} | #{m['label']} |" }
  t['modules'] = (["| ID | #{ja ? 'モジュール' : 'Module'} |", '| ----- | ------ |'] + rows).join("\n") + "\n"
  t['signals'] = side_by_side(['ID', ja ? 'シグナル' : 'Signal'],
    s.signals.sort_by { |sig| sig['id'] }.map { |sig| [sig['id'], s.signal_label(sig, ja: ja)] }, 3)
  t
end

# ---- spms1_main.rb ----------------------------------------------------------------------------

# The wiring of the synth loop, from the requires of the module files on, written out from the spec into the blocks between the
# "# patch_gen NAME" and "# patch_gen end" lines of spms1_main.rb, so that a module is added by
# its class and its entries in the YAML, not by hand in the loop. It is plain straight-line Ruby,
# as it would be written by hand: one local per routing, one call per setter, one `when` per
# module, so that Spinel compiles it as it would a loop written by hand.
#
# A module names its class (`class`), the inputs its `process` takes after the control tick, in
# order (`process`), the method that takes them where it is not `process` (`method`), and each output it has besides the one `process` returns, by the method that
# reads it (`get`); a module whose outputs all have one returns nothing that is used. A parameter
# names the method that takes its value each buffer (`set`).
#
# The dispatch compares against literal ids, and writes to literal bus slots, rather than the
# MODULE_* and SIGNAL_* constants, which Spinel emits as runtime globals (see spms1_main.rb). Each
# literal carries its constant's name in a comment at the end of its line.
def local_name(item) = SPEC.full_key(item).downcase

# What the loop needs of the spec besides what Spec#check asks of every file written from it.
def check_wiring
  s = SPEC
  s.modules.each do |m|
    fail_spec("module #{m['key']} has no class") unless m['class']
    fail_spec("module #{m['key']} has no process") unless m['process'].is_a?(Array)
    m['process'].each do |k|
      fail_spec("module #{m['key']} processes #{k}, not one of its inputs") unless s.inputs.any? { |i| i['module'] == m['key'] && i['key'] == k }
    end
  end
  s.params.each { |c| fail_spec("parameter #{s.full_key(c)} has no set") unless c['set'] }
  names = (s.inputs + s.params).map { |item| local_name(item) }
  names.select { |n| names.count(n) > 1 }.uniq.each { |n| fail_spec("an input and a parameter are both #{n.upcase}") }
end

# A module's class lives in spms1/spms1_<class in snake case>.rb: EnvGen in spms1_env_gen.rb, LFO in
# spms1_lfo.rb.
def class_file(name) = "spms1_#{name.gsub(/([a-z\d])([A-Z])/, '\\1_\\2').downcase}"

def main_requires
  SPEC.modules.map { |m| m['class'] }.uniq.map do |name|
    file = class_file(name)
    fail_spec("class #{name} is not in spms1/#{file}.rb") unless File.exist?(File.join(DIR, 'spms1', "#{file}.rb"))
    "require_relative '#{file}'\n"
  end.join
end

def main_smoothing
  SPEC.modules.select { |m| SMOOTHED_EVERY_16.include?(m['class']) }.map { |m| "      #{m['key'].downcase}.smooth_parameters\n" }.join
end

def main_instances
  SPEC.modules.map { |m| "#{m['key'].downcase} = #{m.fetch('class')}.new(SAMPLE_RATE)\n" }.join
end

def main_sources
  s = SPEC
  out = []
  s.inputs.each do |i|
    name = "source_#{local_name(i)}"
    out << "  #{name} = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_#{s.full_key(i)})\n"
    # A controller slot's smoothed copy in its place (see spms1_main.rb), but for a gate input or a
    # side of the final output: both differences are at least 0 only in the controllers' run of
    # slots. Written out rather than a function or a table, which cost more as Spinel builds them.
    next unless i['module'] && !i['gate']
    out << "  #{name} += ((#{name} - CONTROLLER_SLOT_FIRST) | (CONTROLLER_SLOT_LAST - #{name})) >= 0 ? SMOOTHED_SLOT_OFFSET : 0\n"
  end
  s.params.each do |c|
    out << "  source_#{local_name(c)} = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_#{s.full_key(c)}), SLOT_#{s.full_key(c)})\n"
  end
  out.join
end

def converter(bipolar) = bipolar ? 'cc_to_bipolar' : 'cc_to_unipolar'

def main_controls
  s = SPEC
  out = []
  s.params.each do |c|
    name = local_name(c)
    out << "  cc_#{name} = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_#{s.full_key(c)})\n"
    out << "  signals[SLOT_#{s.full_key(c)}] = #{converter(c['bipolar'])}(cc_or_nrpn(cc_#{name}, C.get_midi_cc_value(MIDI_CH, cc_#{name}), C.get_midi_nrpn_value(MIDI_CH, NRPN_VALUE_#{s.full_key(c)})))\n"
  end
  s.controllers.each do |c|
    name = local_name(c)
    out << "  cc_#{name} = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_#{s.full_key(c)})\n"
    out << "  #{name} = C.get_midi_cc_value(MIDI_CH, cc_#{name})\n"
    plain = "signals[SIGNAL_#{s.full_key(c)}]"
    s.slots_of(c).each do |sig|
      expr = case sig['form']
             when nil then "cc_or_zero(cc_#{name}, #{converter(s.bipolar?(sig))}(#{name}))"
             when 'sin' then "QUARTER_SINE_TABLE[cc_table_index(cc_#{name}, #{name})]"
             when 'cos' then "QUARTER_SINE_TABLE[120 - cc_table_index(cc_#{name}, #{name})]"
             else form_expr(sig['form'], plain)
             end
      out << "  signals[SIGNAL_#{sig['key']}] = #{expr}\n"
    end
  end
  # The smoothed copies, every buffer for every controller whatever reads them, so that what they
  # cost is the same for any patch: the controller's value in two stages, then each form of it.
  s.controllers.each do |c|
    name = local_name(c)
    key = s.full_key(c)
    out << "  signals[SMOOTHED_STAGE_1_#{key}] = Dsp.smooth(signals[SIGNAL_#{key}], signals[SMOOTHED_STAGE_1_#{key}], CONTROLLER_SMOOTHING_BLEND)\n"
    out << "  smoothed_#{name} = Dsp.smooth(signals[SMOOTHED_STAGE_1_#{key}], signals[SIGNAL_#{key} + SMOOTHED_SLOT_OFFSET], CONTROLLER_SMOOTHING_BLEND)\n"
    s.slots_of(c).each do |sig|
      expr = case sig['form']
             when nil then "smoothed_#{name}"
             when 'sin' then "quarter_sine(smoothed_#{name})"
             when 'cos' then "quarter_sine(1.0 - smoothed_#{name})"
             else form_expr(sig['form'], "smoothed_#{name}")
             end
      out << "  signals[SIGNAL_#{sig['key']} + SMOOTHED_SLOT_OFFSET] = #{expr}\n"
    end
  end
  out.join
end

# A form of a controller's value u, written as an expression of `u`.
def form_expr(form, u)
  case form
  when 'rev' then "1.0 - #{u}"
  when 'inv' then "0.0 - #{u}"
  when 'rev_inv' then "#{u} - 1.0"
  when 'bipolar' then "#{u} - 0.5"
  when 'bipolar_inv' then "0.5 - #{u}"
  when 'lo' then "(#{u} < 0.5) ? 1.0 : (2.0 - (#{u} + #{u}))"
  when 'hi' then "(#{u} > 0.5) ? 1.0 : (#{u} + #{u})"
  when 'neg' then "(#{u} > 0.5) ? 0.0 : (1.0 - (#{u} + #{u}))"
  when 'pos' then "(#{u} < 0.5) ? 0.0 : ((#{u} + #{u}) - 1.0)"
  when 'mid' then "(#{u} < 0.5) ? (#{u} + #{u}) : (2.0 - (#{u} + #{u}))"
  end
end

def main_setters
  s = SPEC
  s.controls_in_list_order.reject { |c| c['controller'] }.map do |c|
    "  #{c['module'].downcase}.#{c.fetch('set')}(signals[source_#{local_name(c)}])\n"
  end.join
end

def main_dispatch
  s = SPEC
  out = []
  s.modules.each do |m|
    instance = m['key'].downcase
    args = ['control_tick'] + m.fetch('process').map { |k| "signals[source_#{instance}_#{k.downcase}]" }
    call = "#{instance}.#{m.fetch('method', 'process')}(#{args.join(', ')})"
    outputs = s.outputs_of(m)
    returned = outputs.reject { |o| o['get'] }
    fail_spec("module #{m['key']} has #{returned.size} outputs that `process` returns, not one or none") if returned.size > 1
    out << "      when #{m['id']} # MODULE_#{m['key']}\n"
    out << (returned.empty? ? "        #{call}\n" : "        signals[#{returned[0]['id']}] = #{call} # SIGNAL_#{returned[0]['key']}\n")
    outputs.select { |o| o['get'] }.each do |o|
      out << "        signals[#{o['id']}] = #{instance}.#{o['get']} # SIGNAL_#{o['key']}\n"
    end
  end
  out.join
end

def main_rb(content)
  check_wiring
  { 'requires' => main_requires, 'instances' => main_instances, 'sources' => main_sources, 'controls' => main_controls,
    'setters' => main_setters, 'smoothing' => main_smoothing, 'dispatch' => main_dispatch }.each do |name, text|
    content = replace_block(content, 'spms1/spms1_main.rb', name, text)
  end
  content
end

# ---- writing -----------------------------------------------------------------------------------

# Puts `text` between the lines "<!-- patch_gen NAME -->" (or "// patch_gen NAME") and the next
# "... patch_gen end" in `content`.
def replace_block(content, file, name, text)
  pattern = /^([^\n]*patch_gen #{Regexp.escape(name)}\b[^\n]*\n)(.*?)(^[^\n]*patch_gen end[^\n]*\n)/m
  abort "spms1_patch_gen.rb: #{file} has no patch_gen #{name} block" unless content =~ pattern
  content.sub(pattern) { "#{$1}#{text}#{$3}" }
end

outputs = {}
outputs['spms1/spms1_patch.rb'] = patch_rb
outputs['spms1/spms1_default_patch.h'] = default_patch_h
outputs['spms1/spms1_main.rb'] = main_rb(File.read(File.join(DIR, 'spms1/spms1_main.rb')))
editor = File.read(File.join(DIR, 'spms1_editor.html'))
outputs['spms1_editor.html'] = replace_block(editor, 'spms1_editor.html', 'spec', editor_js)
{ 'spms1_patching.md' => false, 'spms1_patching.ja.md' => true }.each do |file, ja|
  content = File.read(File.join(DIR, file))
  readme_tables(ja: ja).each { |name, text| content = replace_block(content, file, name, "\n#{text}\n") }
  outputs[file] = content
end

check = ARGV.include?('--check')
stale = []
outputs.each do |file, content|
  path = File.join(DIR, file)
  next if File.exist?(path) && File.read(path) == content
  stale << file
  File.write(path, content) unless check
end
if check
  if stale.empty?
    puts 'The files generated from spms1_patch.yaml are up to date'
  else
    puts "Not what spms1_patch.yaml makes (run ruby patch_gen/spms1_patch_gen.rb): #{stale.join(', ')}"
    exit 1
  end
else
  puts stale.empty? ? 'Nothing to write' : "Wrote #{stale.join(', ')}"
end
