module part;

import std.algorithm;

struct Part
{
	string name;
	bool parameter = false;
	bool optional = false;

	this(string part)
	{
		name = part;

		if(name.length == 0)
			return;

		if(name[0] == ':')
		{
			name = name[1..$];
			parameter = true;

			if(name[$-1] == '?')
			{
				name = name[0..$-1];
				optional = true;
			}
		}
	}

	static bool hasOptionalPart(string pattern)
	{
		return pattern.canFind('?');
	}
}
