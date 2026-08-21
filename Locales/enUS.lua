local _, ns = ...

-- English is the base locale. Keys are the English strings themselves, so any
-- missing translation transparently falls back to English.
ns.L = ns.L or setmetatable({}, { __index = function(_, k) return k end })
