module director.splitter_route;

import
	std.regex,
	std.string,
	std.algorithm,
	std.stdio;

import
	director.part,
	director.route;

final class SplitterRoute : Route
{
	debug string _pattern;
	debug string pattern() @property { return _pattern; }

private:
	// The type returned by a splitter operating on strings
	alias SRes = typeof(splitter("", ""));
	SRes parts;

public:
	this(string pattern)
	{
		assert(!Part.hasOptionalPart(pattern),
			"SplitterRoute doens't support optional parts; use RegexRoute");

		debug this._pattern = pattern;
		parts = pattern.normalize.splitter("/");
	}

	bool matches(string pattern, out string[string] matched_params)
	{
		auto pattern_parts = pattern.normalize.splitter("/");
		auto this_parts = parts.save;

		version(none)
		debug
		{
			writeln("Testing pattern: ", pattern);
			writeln("Pattern parts: ", pattern_parts);
			writeln("This parts: ", this_parts);
		}

		foreach(ppart; pattern_parts)
		{
			// We've run out of parts to match on,
			// we're not a match
			if(this_parts.empty)
			{
				return false;
			}

			// The part of this route that is currently being compared on
			auto tpart = Part(this_parts.front);

			if(tpart.parameter)
			{
				// This route part is a variable, extract its name
				// and set this parameter part to it
				matched_params[tpart.name] = ppart;
			}
			else if(tpart.name != ppart)
			{
				// This parameter part isn't the same; this route
				// can't be a match
				return false;
			}

			this_parts.popFront;
		}

		if(!this_parts.empty)
		{
			// Pattern didn't have all the parts that this did,
			// it wasn't a match
			return false;
		}

		// Else, all the parts matched
		return true;
	}
}

unittest
{
	auto r = new SplitterRoute("/foo/bar");
	string[string] params;

	assert(r.matches("/foo/bar", params));
	assert(r.matches("/foo/bar/", params));
}

unittest
{
	auto r = new SplitterRoute("/foo/bar");
	string[string] params;

	assert(!r.matches("/foo", params));
	assert(!r.matches("foo/bar", params));
	assert(!r.matches("/foo//bar", params));
}

unittest
{
	auto r = new SplitterRoute("/:p");
	string[string] params;

	assert(r.matches("/foo", params));
	assert(params["p"] == "foo");

	assert(r.matches("/foo/", params));
	assert(params["p"] == "foo");
}

unittest
{
	auto r = new SplitterRoute("/first/:var1/:var2/last");
	string[string] params;

	assert(r.matches("/first/foo/bar/last", params));
	assert(params["var1"] == "foo");
	assert(params["var2"] == "bar");

	assert(r.matches("/first/foo/bar/last/", params));
	assert(params["var1"] == "foo");
	assert(params["var2"] == "bar");

	assert(!r.matches("/first/foo/last", params));
	assert(!r.matches("/first/foo/bar/last/whut", params));

	assert(!r.matches("/first/foo//bar/last", params));
}
