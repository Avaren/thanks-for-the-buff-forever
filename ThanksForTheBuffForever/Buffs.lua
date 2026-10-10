local _, ns = ...
-- Buff selection adapted from Gogo1951's MIT-licensed TFTB, revision e1f7164.
-- Names are resolved in the client's language and match other ranks too.
ns.buffIDs = {
    -- Explicit ranks avoid depending on uncached spell-name lookups at login.
    1126, 5232, 6756, 5234, 8907, 9884, 9885, -- Mark of the Wild
    1460, 1461, 10156, 10157, -- Arcane Intellect (rank 1 below)
    1244, 1245, 2791, 10937, 10938, -- Power Word: Fortitude
    21849, 5231, 467, -- Druid
    1008, 23028, 1459, 604, -- Mage
    14752, 6346, 21562, 27683, 27681, 1243, 976, -- Priest
    20217, 1044, 19977, 19740, 1022, 20911, 1038, 19742, 19752,
    25898, 25890, 19834, 25899, 25895, 25894, -- Paladin
    2970, 11743, 20707, 5697, -- Warlock
    546, 131, -- Water Walking and Water Breathing
}
