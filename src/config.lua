-- In preset files like Strong.lua, Medium.lua
return {
    -- Enable VM mode
    vmMode = true,
    
    -- VM-specific settings
    vmSettings = {
        obfuscateRuntime = true,
        compressBytecode = true,
        encryptConstants = true,
        shuffleInstructions = false,
        addDummyInstructions = true,
        
        -- Anti-debugging features
        antiDebug = {
            detectDebugger = true,
            checkIntegrity = true,
            randomizeExecution = true
        }
    },
    
    -- Traditional obfuscation steps (ignored in VM mode)
    steps = {
        -- These won't be used when vmMode = true
    }
}