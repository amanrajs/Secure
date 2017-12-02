function c = lineselect(s, maxchars)
error(nargchk(1, 2, nargin));

bad_s = ~ischar(s) || (ndims(s) > 2) || (size(s, 1) ~= 1);
if bad_s
   error('S must be a single-row char array.');
end

if nargin < 2
   maxchars = 80;
end
s = strtrim(s);

exp = sprintf('(\\S\\S{%d,}|.{1,%d})(?:\\s+|$)', maxchars, maxchars);

tokens = regexp(s, exp, 'tokens').';
get_contents = @(f) f{1};
c = cellfun(get_contents, tokens, 'UniformOutput', false);

c = deblank(c);

