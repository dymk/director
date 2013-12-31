module director.regex_route;

import
	std.string,
	std.algorithm,
	std.regex,
	std.typetuple,
	std.stdio;

import
	director.part,
	director.route;

final class RegexRoute : Route
{
	debug string _pattern;
	debug string pattern() @property { return _pattern; }

private:
	Regex!char r;
	typeof((Regex!char).init.namedCaptures) nc;

public:
	this(string pattern)
	{
		debug this._pattern = pattern;

		// Builds a named capture group with %s as the name
		static immutable namedmatch_str = `(?P<%s>\w+)`;

		string regex_str = "^";
		foreach(i, part_str; pattern.normalize.split("/"))
		{
			auto part = Part(part_str);
			string appended;

			if(part.parameter)
			{
				appended = namedmatch_str.format(part.name);
				if(part.optional)
				{
					// '?' to make the capture group optional
					appended ~= "?";
				}
			}
			else
			{
				appended = part.name;
			}

			if(i != 0)
			{
				if(part.optional)
				{
					appended = "/?" ~ appended;
				}
				else
				{
					appended = "/" ~ appended;
				}
			}

			regex_str ~= appended;
		}

		regex_str ~= "$";

		version(DRouterDebug) debug writefln("Regex for pattern %s: %s", pattern, regex_str);

		r = regex(regex_str);
		nc = r.namedCaptures;
	}

	bool matches(string pattern, out string[string] matched_params)
	{
		auto m = match(pattern.normalize, r);

		if(m.empty)
		{
			return false;
		}

		auto captures = m.captures;
		foreach(name; nc)
		{
			auto capture = captures[name];
			if(capture.length)
			{
				matched_params[name] = capture;
			}
		}
		return true;
	}
}

unittest
{
	auto r = new RegexRoute("/:p?");
	string[string] params;

	assert(r.matches("/foo", params));
	assert(params["p"] == "foo");

	assert(r.matches("/foo/", params));
	assert(params["p"] == "foo");

	assert(r.matches("/", params));
	assert("p" !in params);
}

unittest
{
	auto r = new RegexRoute("/:first?/:last");
	string[string] params;

	assert(r.matches("/foo", params));
	assert(params["last"] == "foo");
	assert("first" !in params);

	assert(r.matches("/foo/", params));
	assert(params["last"] == "foo");
	assert("first" !in params);

	assert(r.matches("/bar/foo", params));
	assert(params["first"] == "bar");
	assert(params["last"] == "foo");

	assert(r.matches("/bar/foo/", params));
	assert(params["first"] == "bar");
	assert(params["last"] == "foo");

	assert(!r.matches("/foo//", params));
}

// Copied from SplitterRoute
unittest
{
	auto r = new RegexRoute("/foo/bar");
	string[string] params;

	assert(r.matches("/foo/bar", params));
	assert(r.matches("/foo/bar/", params));
}

unittest
{
	auto r = new RegexRoute("/foo/bar");
	string[string] params;

	assert(!r.matches("/foo", params));
	assert(!r.matches("foo/bar", params));
	assert(!r.matches("/foo//bar", params));
}

unittest
{
	auto r = new RegexRoute("/:p");
	string[string] params;

	assert(r.matches("/foo", params));
	assert(params["p"] == "foo");

	assert(r.matches("/foo/", params));
	assert(params["p"] == "foo");
}

unittest
{
	// Limitation in std.regex: named groups can't have numbers in them
	// Crashes with an error like `Pattern with error: `(?P<var1` <--HERE-- `>\w+)``
	//auto r = new RegexRoute("/first/:var1/:var2/last");

	auto r = new RegexRoute("/first/:varone/:vartwo/last");
	string[string] params;

	assert(r.matches("/first/foo/bar/last", params));
	assert(params["varone"] == "foo");
	assert(params["vartwo"] == "bar");

	assert(r.matches("/first/foo/bar/last/", params));
	assert(params["varone"] == "foo");
	assert(params["vartwo"] == "bar");

	assert(r.matches("/first/1/003/last/", params));
	assert(params["varone"] == "1");
	assert(params["vartwo"] == "003");

	assert(!r.matches("/first/foo/last", params));
	assert(!r.matches("/first/foo/bar/last/whut", params));

	assert(!r.matches("/first/foo//bar/last", params));
}
