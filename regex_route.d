module regex_route;

import
	std.string,
	std.algorithm,
	std.regex,
	std.typetuple,
	std.stdio;

import part, route;

final class RegexRoute : Route
{
	debug string _pattern;
	string pattern() @property { return _pattern; }

private:
	Regex!char r;
	typeof(r.namedCaptures) nc;

public:
	this(string pattern)
	{
		debug this._pattern = pattern;

		// Does a named match
		static immutable namedmatch_str = `(?P<%s>\w+)`;

		string regex_str = "^";
		foreach(i, part_str; pattern.split("/"))
		{
			auto part = Part(part_str);
			string appended;

			if(part.parameter)
			{
				appended = namedmatch_str.format(part.name);
				if(part.optional)
				{
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

		debug writefln("Regex for pattern %s: %s", pattern, regex_str);

		r = regex(regex_str);
		nc = r.namedCaptures;
	}

	bool matches(string pattern, out string[string] matched_params)
	{
		auto m = match(pattern, r);

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
