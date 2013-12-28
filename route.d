module route;

interface Route
{
	bool matches(string pattern, out string[string] matched_params);
	debug string pattern() @property;
}
