import re

file_path = 'lib/services/localization_service.dart'
with open(file_path, 'r') as f:
    lines = f.readlines()

error_lines = [1440, 1450, 1940, 2428, 2677, 2931, 3185, 3439, 3693, 3947, 4201, 4443, 4694, 4955, 5197, 5459]

for i in error_lines:
    idx = i - 1
    # Check if the line looks like a loose string (starts with spaces and ')
    if re.match(r'^\s*\'', lines[idx]):
        lines[idx] = lines[idx].replace("'", f"'dummy_key_{i}': '", 1)

with open(file_path, 'w') as f:
    f.writelines(lines)
print("Done")
