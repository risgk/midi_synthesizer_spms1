# Writes what the sketch reads from spms1_patch.yaml: spms1/spms1_patch.rb whole, the parts of
# spms1_editor.html, README.md and README.ja.md between their "patch_gen" markers, and the module
# ids and output slots of the dispatch in spms1/spms1_main.rb.
#
#   ruby patch_gen/spms1_patch_gen.rb [--check]
#
# --check writes nothing, and exits with 1 if a file is not what it would write. Needs CRuby only
# (YAML and JSON are in its standard library). Run from anywhere.

require 'yaml'
require 'json'

# The READMEs are UTF-8 whatever the locale (Windows', or a CI runner's) says.
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

DIR = File.expand_path('..', __dir__)
SPEC_FILE = File.join(DIR, 'spms1_patch.yaml')

NRPN_ACTIVE_MODULE_BASE = 0
NRPN_INPUT_BASE         = 128
NRPN_PARAM_SOURCE_BASE  = 256
NRPN_CC_BASE            = 384

# A parameter source of 127 is the parameter's own control slot, which is off the bus: the bus
# carries the outputs, the constants, the notes and the General slots in 0-126, and each
# parameter's control slot sits at 128 + its entry, where only the parameter reads it.
SIGNAL_OWN      = 127
PARAM_SLOT_BASE = 128

def fail_spec(message)
  abort "spms1_patch_gen.rb: spms1_patch.yaml: #{message}"
end

# The spec, read and checked: every number unique, every key it names defined.
class Spec
  attr_reader :modules, :signals, :inputs, :inputs_in_list_order, :controls, :controls_in_list_order, :default_order

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
    @module = @modules.to_h { |m| [m['key'], m] }
    @control = @controls.to_h { |c| [full_key(c), c] }
    @signal = @signals.to_h { |s| [s['key'], s] }
    check
  end

  def module(key) = @module.fetch(key)
  def control(key) = @control.fetch(key)
  def signal(key) = @signal.fetch(key)

  # A module input's or control's own name, with its module's in front: OSC_1_PITCH, OUTPUT_L.
  def full_key(item) = item['module'] ? "#{item['module']}_#{item['key']}" : item['key']

  def full_label(item, name = item['label'])
    if item['module'] then "#{self.module(item['module'])['label']} #{name}"
    elsif item['general'] then "General #{name}"
    else name
    end
  end

  def params = @controls.reject { |c| c['general'] }
  def generals = @controls.select { |c| c['general'] }
  def outputs_of(mod) = @signals.select { |s| s['output'] && s['module'] == mod['key'] }
  # The bus slots a General control's CC fills; a parameter's control slot is its own, off the bus.
  def slots_of(control) = @signals.select { |s| s['control'] == full_key(control) }

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
      fail_spec("signal #{s['key']} is a parameter's control slot, which is off the bus") if s['control'] && !@control[s['control']]['general']
    end
    (@inputs + @controls).each do |item|
      fail_spec("#{full_key(item)} names module #{item['module']}") if item['module'] && !@module[item['module']]
      fail_spec("#{full_key(item)} takes #{item['source']}, no signal") if item['source'] && !@signal[item['source']]
    end
    @controls.each do |c|
      fail_spec("General control #{full_key(c)} fills no slot") if c['general'] && slots_of(c).empty?
      fail_spec("control #{full_key(c)} has a CC but no value") if c['cc'].to_i != 0 && !c.key?('value')
    end
  end
end

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
  out << "\n\n# NRPN parameter numbers: (MSB << 7) | LSB, where the MSB picks a category and the LSB an entry.\n"
  out << "#   0..127   active_modules[slot]\n# 128..255   what feeds each module input\n"
  out << "# 256..383   where each parameter's value comes from\n# 384..511   which CC fills each control slot\n"
  out << "NRPN_ACTIVE_MODULE_BASE = #{NRPN_ACTIVE_MODULE_BASE}\n\n"
  out << ruby_constants(s.inputs.map { |i| ["NRPN_SOURCE_#{s.full_key(i)}", NRPN_INPUT_BASE + i['entry']] })
  out << "\n\n"
  out << ruby_constants(s.params.map { |c| ["NRPN_SOURCE_#{s.full_key(c)}", NRPN_PARAM_SOURCE_BASE + c['entry']] })
  out << "\n\n# A CC number of 0 means the parameter has no CC: its control slot holds 0.0 -- the bottom of a\n"
  out << "# unipolar dial, the middle of a bipolar one -- whatever CC it had before, so a patch sets it alone.\n"
  out << ruby_constants(s.controls.map { |c| ["NRPN_CC_#{s.full_key(c)}", NRPN_CC_BASE + c['entry']] })
  out << "\n\n# The constants of the bus, which nothing else ever writes. A slot not written here holds 0.0.\n"
  out << "def spms1_fill_constant_signals(signals)\n"
  consts = s.signals.select { |sig| sig.key?('value') && sig['value'] != 0.0 }
  width = consts.map { |sig| sig['key'].length }.max
  consts.each do |sig|
    out << "  signals[SIGNAL_#{sig['key']}]#{' ' * (width - sig['key'].length)} = #{format('%4.1f', sig['value'])}\n"
  end
  out << "end\n\n"
  out << "# The default patch, written into the NRPN table, and the values its CCs power up at.\n"
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
  with_cc.each do |c|
    out << "  C.set_midi_cc_value(midi_ch, #{c['cc'].to_s.ljust(3)}, #{c['value'].to_s.ljust(3)}) # #{s.full_label(c)}\n"
  end
  out << "end\n"
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
            general: !!c['general'],
            slots: if c['general']
                     s.slots_of(c).map do |sig|
                       [sig['key'], sig['label'] ? sig['label'].sub(/\AGeneral /, '') : c['label'], s.bipolar?(sig)]
                     end
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
  }
  lines = ['  const SPEC = {']
  spec.each do |name, list|
    if list.first.is_a?(String)
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

# ---- README.md, README.ja.md -------------------------------------------------------------------

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
  t['inputs'] = side_by_side(['CC 98', ja ? 'モジュール入力' : 'Module input'],
    s.inputs.map { |i| [i['entry'], s.full_label(i, (ja && i['name_ja']) || i['name'])] }, 2)
  t['params'] = side_by_side(['CC 98', ja ? 'パラメータ' : 'Parameter'],
    s.params.map { |c| [c['entry'], s.full_label(c)] }, 3)
  sep = ja ? '、' : ', '
  rows = s.generals.map do |c|
    "| #{c['entry']} | #{s.full_label(c)} | #{s.slots_of(c).map { |sig| sig['label'] || s.full_label(c) }.join(sep)} |"
  end
  t['generals'] = (["| CC 98 | #{ja ? 'CC の割り当て先' : 'CC for'} | #{ja ? '埋めるスロット' : 'Fills'} |",
                    '| ----- | ------ | ----- |'] + rows).join("\n") + "\n"
  rows = ["| 0 | #{ja ? 'なし（実行順の終端）' : 'None (ends the run order)'} |"] +
         s.modules.map { |m| "| #{m['id']} | #{m['label']} |" }
  t['modules'] = (["| ID | #{ja ? 'モジュール' : 'Module'} |", '| ----- | ------ |'] + rows).join("\n") + "\n"
  t['signals'] = side_by_side(['ID', ja ? 'シグナル' : 'Signal'],
    s.signals.sort_by { |sig| sig['id'] }.map { |sig| [sig['id'], s.signal_label(sig, ja: ja)] }, 3)
  t
end

# ---- spms1_main.rb ----------------------------------------------------------------------------

# The module dispatch of the per-sample loop compares against literal ids, and writes to literal
# bus slots, rather than the MODULE_* and SIGNAL_* constants, which Spinel emits as runtime globals
# (see spms1_main.rb). Each literal carries its constant's name in a comment at the end of its
# line, `when 3 # MODULE_OSC_1` and `signals[11] = ... # SIGNAL_OSC_1_OUTPUT`, and this writes the
# number from the spec. Every module has to have exactly one `when` and every module output exactly
# one write, and nothing else may be named.
def main_rb(content)
  s = SPEC
  module_ids = s.modules.to_h { |m| [m['key'], m['id']] }
  signal_ids = s.signals.to_h { |sig| [sig['key'], sig['id']] }
  seen_modules = Hash.new(0)
  seen_outputs = Hash.new(0)
  out = content.gsub(/^(\s*when )\d+( # MODULE_(\w+))$/) do
    head, tail, key = $1, $2, $3
    abort "spms1_patch_gen.rb: spms1_main.rb names MODULE_#{key}, no module" unless module_ids.key?(key)
    seen_modules[key] += 1
    "#{head}#{module_ids[key]}#{tail}"
  end
  out = out.gsub(/^(\s*signals\[)\d+(\] = .* # SIGNAL_(\w+))$/) do
    head, tail, key = $1, $2, $3
    abort "spms1_patch_gen.rb: spms1_main.rb names SIGNAL_#{key}, no signal" unless signal_ids.key?(key)
    seen_outputs[key] += 1
    "#{head}#{signal_ids[key]}#{tail}"
  end
  s.modules.each do |m|
    n = seen_modules[m['key']]
    abort "spms1_patch_gen.rb: spms1_main.rb has #{n} `when ... # MODULE_#{m['key']}`, not one" unless n == 1
    s.outputs_of(m).each do |o|
      n = seen_outputs[o['key']]
      abort "spms1_patch_gen.rb: spms1_main.rb has #{n} `signals[...] = ... # SIGNAL_#{o['key']}`, not one" unless n == 1
    end
  end
  out
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
outputs['spms1/spms1_main.rb'] = main_rb(File.read(File.join(DIR, 'spms1/spms1_main.rb')))
editor = File.read(File.join(DIR, 'spms1_editor.html'))
outputs['spms1_editor.html'] = replace_block(editor, 'spms1_editor.html', 'spec', editor_js)
{ 'README.md' => false, 'README.ja.md' => true }.each do |file, ja|
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
