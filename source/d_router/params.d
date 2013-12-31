module director.params;

import std.variant;

struct Params
{
private:
	string[string] params;

public:
	Variant extra;

public:
	this(string[string] params, Variant extra)
	{
		this(params);
		this.extra = extra;
	}

	this(string[string] params)
	{
		this.params = params;
	}

	bool has(string name)
	{
		return (name in this) !is null;
	}

	string* opBinaryRight(string op)(string name)
	if(op == "in")
	{
		return name in params;
	}

	auto opIndex(string name)
	in
	{
		assert(has(name));
	}
	body
	{
		return params[name];
	}

	string opDispatch(string name)()
	{
		return this[name];
	}
}

unittest
{
	auto p = Params(["foo": "bar"]);
	assert(p.foo == "bar");
	assert(p["foo"] == "bar");
}
