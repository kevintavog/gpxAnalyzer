import GpxFilterCore

var registry = CommandRegistry(usage: "<command> <options>", overview: "Filter GPX files")

registry.register(commands: [InfoCommand.self, TimeCommand.self])

registry.run()
