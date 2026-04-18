-- ================================================================
-- VM Strong Preset
-- Maximum protection using VM + obfuscation
-- ================================================================

return {
    LuaVersion = "Lua51";
    VarNamePrefix = "";
    NameGenerator = "MangledShuffled";
    PrettyPrint = false;
    Seed = 0;
    
    Steps = {
        -- Phase 1: Rename everything
        {
            Name = "Rename";
            Settings = {
                RenameVariables = true;
                RenameGlobals = false;
                RenameUpvalues = true;
            };
        };
        
        -- Phase 2: Encrypt constants
        {
            Name = "ConstantArray";
            Settings = {
                Treshold = 1;
                StringsOnly = false;
                Shuffle = true;
                Rotate = true;
            };
        };
        
        -- Phase 3: Add string encryption
        {
            Name = "StringsToExpressions";
            Settings = {};
        };
        
        -- Phase 4: Control flow obfuscation
        {
            Name = "ControlFlowFlattening";
            Settings = {
                Treshold = 1;
            };
        };
        
        -- Phase 5: Wrap in functions
        {
            Name = "WrapInFunction";
            Settings = {};
        };
        
        -- Phase 6: Add anti-tampering
        {
            Name = "AntiTamper";
            Settings = {
                IntegrityCheck = true;
                AntiDebug = true;
            };
        };
        
        -- Phase 7: Convert to VM (MUST BE LAST)
        {
            Name = "Vmify";
            Settings = {
                CustomOpcodes = true;
                AntiDebug = true;
                IntegrityCheck = true;
            };
        };
    };
}