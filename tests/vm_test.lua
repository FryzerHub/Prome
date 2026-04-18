local VM = require("prometheus.vm");

-- Test simple code
local testCode = [[
print("Hello, World!")
local x = 10
local y = 20
print(x + y)
]];

print("Compiling test code...");
local vmCode = VM.compile(testCode);

print("\n--- VM Output ---");
print(vmCode);
print("\n--- End VM Output ---");

-- Test execution
print("\nExecuting VM code...");
local func = loadstring(vmCode);
if func then
    func();
    print("✓ VM code executed successfully");
else
    print("✗ VM code failed to load");
end