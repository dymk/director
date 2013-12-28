import
	std.stdio,
	std.regex,
	std.string,
	std.algorithm,
	std.typetuple,
	std.variant;

import route, regex_route, splitter_route, part;

struct Router
{
	alias CBType = void delegate(string[string]);

	struct RouteCallbackPair
	{
		Route route;
		CBType callback;
	}

	RouteCallbackPair[] routes;

	void push(string route_pattern, CBType callback)
	{
		Route route;
		if(Part.hasOptionalPart(route_pattern))
		{
			route = new RegexRoute(route_pattern);
		}
		else
		{
			route = new SplitterRoute(route_pattern);
		}

		push(route, callback);
	}

	void push(Route route, CBType callback)
	{
		routes ~= RouteCallbackPair(route, callback);
	}

	void match(string pattern)
	{
		string[string] matched_params;
		foreach(ref pair; routes)
		{
			if(pair.route.matches(pattern, matched_params))
			{
				debug writefln("Matched route: %s", pair.route.pattern);
				pair.callback(matched_params);
				return;
			}
		}

		debug writeln("Didn't match any routes");
	}
}

void main()
{
	auto router = Router();

	router.push("/foo/bar", (params) {
		writeln("foo/bar was called");
	});

	router.push("/baz/:name", (params) {
		writefln("Baz called with name: %s", params["name"]);
	});

	router.push("/baz/:name/:occupation", (params) {
		writefln("You're %s and you do %s", params["name"], params["occupation"]);
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

	version(unittest)
	{
		writeln("All unittests pass");
		return;
	}

	while(true)
	{
		write("> ");
		string line = readln();
		if(line is null)
			break;

		router.match(line.chomp.strip);
	}
}
