function stim_table = create_stimtable(kwargs)
% Author: Pai
% Returns the stimulus information table for the given keyword arguments.
% Uses name=value syntax to allow for flexible and explicit arguments.
    arguments
        kwargs.params struct % Struct of parameters, order sensitive
    end

    function cart_prod = cartprod(sets)
    % A function to prepare the Cartesian product of sets, respecting the order they are provided in.
    % Alternative formulations exist, including one that uses recursion. Refer Keerthan's notes.
    
        idx_max = 1; for s = 1:length(sets), idx_max = idx_max*length(sets{s}); end  % Total possible combinations
        
        increments_at = 1; for s = length(sets):-1:2, increments_at = [increments_at(1)*length(sets{s}), increments_at]; end % Number of idx steps before modular increment applicable to the set
        
        cart_prod = num2cell(NaN*ones(idx_max, length(sets)));
        idx = (1:idx_max)';
        
        idx_mapping = @(idx, increment_at, cardinality) ...
            mod(floor(mod(idx - 1, increment_at)/increment_at) + floor((idx - 1)/increment_at), cardinality) + 1; % A nifty, inductive algo. that uses modular arithmetic and set order to determine the combination index given the row index. Refer my notebook for more details!
        
        for s = length(sets):-1:1
            foo = sets{s}(idx_mapping(idx, increments_at(s), length(sets{s})));
            if class(foo) == "double"
                cart_prod(:, s) = num2cell(foo)';
            else
                cart_prod(:, s) = cellstr(foo)';
            end
        end
    
    end

    % Creating the stimulus table:
    stim_table = cell2table(cartprod(struct2cell(kwargs.params)), 'VariableNames', string(fieldnames(kwargs.params))');
end