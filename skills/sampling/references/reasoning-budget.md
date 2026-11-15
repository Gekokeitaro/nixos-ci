# Reasoning budget

A model that reasons writes a thinking block first. `reasoning_budget` caps it:
−1 unrestricted (the default), 0 no reasoning, N a token limit. When it runs out
the server forces the block closed and injects `reasoning_budget_message` before
the end-of-thinking tag: *budget forcing* is the server acting, not the model
deciding to stop.

It is not `max_tokens`/`n_predict`: that caps the whole output, thinking included,
and running out mid-thought truncates the answer. The budget caps only the
thinking and leaves room to answer.

`:instruct` turns reasoning off through the template (`chat_template_kwargs`),
not through the budget.
