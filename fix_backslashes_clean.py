import re

loc_path = 'lib/services/localization_service.dart'
with open(loc_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace any sequence of \\\\ or \n messes with clean newline or clean string
# Specifically check lines like '...\\\\\\\\...'
def clean_line(line):
    # If line has multiple backslashes
    if '\\\\' in line:
        # replace '\\\\\\\\n' or any number of backslashes before n with '\n'
        line = re.sub(r'\\+n', r'\\n', line)
        # replace multiple backslashes before single quote with single \'
        line = re.sub(r'\\+\'', r"\\'", line)
        # replace any remaining consecutive backslashes
        line = re.sub(r'\\\\+', r'\\', line)
    return line

lines = text.split('\n')
cleaned_lines = [clean_line(l) for l in lines]
new_text = '\n'.join(cleaned_lines)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(new_text)

print("Cleaned backslashes successfully!")
