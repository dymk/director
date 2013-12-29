import d_router.router;

import
	std.stdio,
	std.string;

version(unittest)
{
	void main() { writeln("All unittests pass"); }
}
else:

void main()
{
	auto router = Router();

	router.push("/foo/bar", (params) {
		writeln("/foo/bar was called");
	});

	router.push("/job/:name/:occupation", (params) {
		writefln("%s is a %s", params["name"], params["occupation"]);
	});

	router.push("/user/:name?", (params) {
		auto name = "name" in params;
		if(name is null)
		{
			writeln("You didn't supply a name!");
		}
		else
		{
			writefln("Hello, %s", *name);
		}
	});

	int i = 0;
	router.push("/callme", (params) {
		i++;
		writefln("Been called %d times", i);
	});

	writeln("Router Demo: View source/app.d");
	while(true)
	{
		write("> ");
		string line = readln();
		if(line is null || !line.chomp.length)
			break;

		router.match(line.chomp.strip);
	}
}
