# Matlab (mainly functions)

All of my functions follow a particular style when it comes to handling
optional input arguments (varargins). I got annoyed with the common approach
of doing a lot of if statements for all the possible inputs, since it can can
get quite long and push the meat of the function way down the page if there are
a lot of possibilities:
``` matlab
if size(varargin,2)==1
    % do something
end

if size(varargin,2)==2
    % do something else
end
.
.
.
% real code begins 
```

So I came up with the solution of passing a single optional argument, which is
a structure in which the fieldnames are the optional variable names used by the
function and the value of each field is the value that will be assigned to the
variable inside the function.

For example: 
``` matlab
clear optional_params
optional_params.my_first_variable = 5;
optional_params.my_second_variable = 8;
out = myfuncion(<mandatory_arg1>, <mandatory_arg2>, optional_params);
```

Within the function, these variables will be initialised like:
``` matlab
my_first_variable = 5;
my_second_variable = 8;
```

This is achieved by something like the following code, which loops over the
fieldnames in optional_params and uses the eval() function to set the variables
with the values that were passed in. No matter how many optional arguments are
passed (in the form of fieldnames), the amount of code to deal with them stays
fixed and I can just write the rest of function assuming their existence:
``` matlab
%% set default values for optional variables
my_first_variable = 1;
my_second_variable = 2;

%% override optional arguments
% if varagin variables have been provided, overwrite the above default
% values with provided values
if ~isempty(varargin)
    if size(fieldnames(varargin{1}), 1) ~= 0
        vars_in_fields = fieldnames(varargin{1});
        for i = 1:numel(vars_in_fields)
            if ~exist(vars_in_fields{i}, 'var')
                error(['one or more of varargins does not correspond ',...
                    'exactly to any variable name used in the function'])
            end
        end
        additional_params = varargin{1};
        for additional_params_index = 1:size(fieldnames(varargin{1}), 1)
            eval([vars_in_fields{additional_params_index},...
                ' = additional_params.',...
                vars_in_fields{additional_params_index}, ';'])
        end
    end
end
```
