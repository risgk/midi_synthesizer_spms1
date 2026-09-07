module Spms1
  # Indices into modules, the pool of instantiated processing modules. MODULE_NONE (0) is reserved
  # as the sentinel for "no module assigned" so that active_module_indices (see main) can stay a
  # plain, fixed-length, all-Integer array instead of relying on nil -- friendlier to Spinel
  # compilation.
  module ModuleIndex
    MODULES_SIZE = 128
    # Row length for module_input_signal_indices (see main); the widest module (Filter) uses 5.
    MODULE_MAX_ARGS = 8

    MODULE_NONE = 0
    ENV_GEN     = 1
    OSCILLATOR  = 2
    FILTER      = 3
    AMP         = 4
  end
end
