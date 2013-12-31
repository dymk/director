module director.route;

interface Route
{
	bool matches(string pattern, out string[string] matched_params);
	debug string pattern() @property;
}

// removes the trailing slash from a pattern
package string normalize(string pattern)
{
	if(pattern.length > 1 && pattern[$-1] == '/')
	{
		return pattern[0..$-1];
	}

	return pattern;
}
