import Foundation

let args = CommandLine.arguments
if args.count < 2 {
    print("""
    Usage: majordomo <command> [arguments]

    Commands:
      tools       List available tools
      run         Call a tool with JSON parameters
      schema      Get tool schema
      status      Check server status

    Majordomo.app must be running.
    """)
    exit(0)
}

print("error: not yet implemented", to: &standardError)
exit(1)

var standardError = FileHandle.standardError

extension FileHandle: @retroactive TextOutputStream {
    public func write(_ string: String) {
        let data = Data(string.utf8)
        self.write(data)
    }
}
