module d_router.router;

import
	std.stdio,
	std.regex,
	std.string,
	std.algorithm,
	std.typetuple,
	std.typetuple;

import
	d_router.route,
	d_router.regex_route,
	d_router.splitter_route,
	d_router.part;

private
{
	alias CB_Delegate_Params = void delegate(string[string]);
	alias CB_Function_Params = void function(string[string]);
	alias CB_Delegate        = void delegate();
	alias CB_Function        = void function();

	enum isCallback(T) =
		is(T == CB_Function) || is(T == CB_Function_Params) ||
		is(T == CB_Delegate) || is(T == CB_Delegate_Params);

	struct RouteCallbackPair
	{
		Route route;
		union
		{
			CB_Delegate        d_callback;
			CB_Function        f_callback;
			CB_Delegate_Params dp_callback;
			CB_Function_Params fp_callback;
		}
		bool is_delegate;
		bool takes_params;

		this(CBType)(Route r, CBType cb)
		if(isCallback!CBType)
		{
			route = r;

			static if(is(CBType == delegate))
			{
				is_delegate = true;

				static if(is(CBType == CB_Delegate))
					d_callback = cb;
				else
				{
					takes_params = true;
					dp_callback = cb;
				}
			}
			else
			{
				is_delegate = false;

				static if(is(CBType == CB_Function))
					f_callback = cb;
				else
				{
					takes_params = true;
					fp_callback = cb;
				}
			}
		}
	}
}

struct Router
{
private:
	RouteCallbackPair[] routes;

	Route routeFor(string route_pattern)
	{
		if(Part.hasOptionalPart(route_pattern))
			return new RegexRoute(route_pattern);
		else
			return new SplitterRoute(route_pattern);
	}

public:

	// Order is important here: Prefer function type
	// callbacks above delegates in order to not
	// allocate a delegate's environment on each invocation
	ref Router push(string route_pattern, CB_Function callback)
	{
		return push(routeFor(route_pattern), callback);
	}

	ref Router push(string route_pattern, CB_Function_Params callback)
	{
		return push(routeFor(route_pattern), callback);
	}

	ref Router push(string route_pattern, CB_Delegate callback)
	{
		return push(routeFor(route_pattern), callback);
	}

	ref Router push(string route_pattern, CB_Delegate_Params callback)
	{
		return push(routeFor(route_pattern), callback);
	}

	ref Router push(CBType)(Route route, CBType callback)
	if(isCallback!CBType)
	{
		routes ~= RouteCallbackPair(route, callback);
		return this;
	}

	bool match(string pattern)
	{
		string[string] matched_params;
		foreach(ref pair; routes)
		{
			if(pair.route.matches(pattern, matched_params))
			{
				if(pair.is_delegate)
				{
					if(pair.takes_params)
						pair.dp_callback(matched_params);
					else
						pair.d_callback();
				}
				else
				{
					if(pair.takes_params)
						pair.fp_callback(matched_params);
					else
						pair.f_callback();
				}

				return true;
			}
		}

		return false;
	}
}

unittest
{
	auto r = Router();
	bool hit = false;

	r.push("/foo", () { hit = true; });
	r.push("/bar", () { hit = false; });

	assert(r.match("/foo"));
	assert(hit);

	assert(!r.match("/asdf"));
	assert(!r.match("/foo/bar"));
	assert(!r.match("/bar/foo"));
}

unittest
{
	auto r = Router();

	string hit;

	r
	.push("/a/a", { hit = "aye"; })
	.push("/a/b", { hit = "bee"; })
	.push("/a/:o", (p) { hit = p["o"]; });

	assert(!r.match("/a/"));
	assert(!r.match("/a"));

	assert(r.match("/a/a"));
	assert(hit == "aye");

	assert(r.match("/a/b"));
	assert(hit == "bee");

	assert(r.match("/a/foo"));
	assert(hit == "foo");

	assert(r.match("/a/z"));
	assert(hit == "z");
}
