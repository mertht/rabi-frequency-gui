function num = getN(tag)
% getN returns get(handles.___, 'String') cast to a double.
    num = str2double(get(tag, 'String'));
end