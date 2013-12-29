module d_router.router;

import
	std.stdio,
	std.regex,
	std.string,
	std.algorithm,
	std.typetuple,
	std.variant;

import
	d_router.route,
	d_router.regex_route,
	d_router.splitter_route,
	d_router.part;

private
{
	alias CB_Delegate = void delegate(string[string]);
	alias CB_Function = void function(string[string]);
	enum isCallback(T) = is(T == CB_Function) || is(T == CB_Delegate);

	struct RouteCallbackPair
	{
		Route route;
		union
		{
			CB_Delegate d_callback;
			CB_Function f_callback;
		}
		bool is_delegate = false;

		this(CBType)(Route r, CBType cb)
		if(isCallback!CBType)
		{
			route = r;
			static if(is(CBType == CB_Delegate))
			{
				d_callback = cb;
				is_delegate = true;
			}
			else
			{
				f_callback = cb;
				is_delegate = false;
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
	void push(string route_pattern, CB_Function callback)
	{
		push(routeFor(route_pattern), callback);
	}

	void push(string route_pattern, CB_Delegate callback)
	{
		push(routeFor(route_pattern), callback);
	}

	void push(CBType)(Route route, CBType callback)
	if(isCallback!CBType)
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

				if(pair.is_delegate)
					pair.d_callback(matched_params);
				else
					pair.f_callback(matched_params);

				return;
			}
		}

		debug writeln("Didn't match any routes");
	}
}
