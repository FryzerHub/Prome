-- VM Module Loader
return {
    Instruction = require("prometheus.vm.Instruction"),
    Opcode = require("prometheus.vm.Opcode"),
    Compiler = require("prometheus.vm.Compiler"),
    Runtime = require("prometheus.vm.Runtime"),
    Deserializer = require("prometheus.vm.Deserializer"),
}