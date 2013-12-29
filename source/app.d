import
		d_router.router,
		d_router.splitter_route,
		d_router.regex_route;

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

	/**
	 * Passing functions as handlers
	 */
	router.push("/foo/bar", {
		writeln("/foo/bar was called");
	});

	/**
	 * Passing functions as handlers, which take a
	 * string[string] containing the params hash
	 */
	router.push("/job/:name/:occupation", (params) {
		writefln("%s is a %s", params["name"], params["occupation"]);
	});

	/**
	 * Optional route parts
	 * This will match on /user, or /user/bob
	 */
	router.push("/user/:name?", (params) {

		auto name = "name" in params;
		if(name is null)
		{
			writeln("You didn't supply a name!");
		}
		else
		{
			writeln("Hello, ", *name);
		}

	});

	/**
	 * Delegate support
	 */
	int i = 0;
	router.push("/callme", {

		i++;
		writefln("Been called %d times", i);

	});

	/**
	 * Delegate with param support
	 */
	string[] seen_names;
	router.push("/addname/:name", (params) {

		seen_names ~= params["name"];
		writeln("Seen names: ", seen_names);

	});

	/**
	 * Push method chaining
	 */
	router
	.push("/chained/a", () { writeln("Matched a"); })
	.push("/chained/b", () { writeln("Matched b"); })
	.push("/chained/:o", (params) {
		writeln("Matched other: ", params["o"]);
	});

	bench();

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

void bench()
{
	// Benchmark for Splitter vs Regex based route matchers
	import std.datetime;

	static void nil(string[string] params) {}

	Router r1 = Router();
	Router r2 = Router();

	foreach(pattern; ["/foo", "/:name", "/foo/:bar/:baz"])
	{
		r1.push(new SplitterRoute(pattern), &nil);
		r2.push(new RegexRoute(pattern), &nil);
	}

	void doMatch(ref Router r)
	{
		r.match("/baz");
	}

	void testr1()
	{
		foreach(i; 0..500_000)
		{
			doMatch(r1);
		}
	}

	void testr2()
	{
		foreach(i; 0..500_000)
		{
			doMatch(r2);
		}
	}

	writeln("Benchmark: SplitterRoute vs RegexRoute, 500K matches, running...");
	auto results = benchmark!(testr1, testr2)(1);
	writefln("Splitter: %s msecs\nRegex: %s msecs\n", results[0].msecs, results[1].msecs);
}
