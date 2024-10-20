import csv
import yaml
import sys
import os

def convert_csv_to_yaml(input_file):
    output_file = os.path.splitext(input_file)[0] + '.yml'

    with open(input_file, 'r', encoding='ISO-8859-1') as file:
        lines = file.readlines()
    
    start_index = None
    for i, line in enumerate(lines):
        if "Spectrum in [nm]" in line:
            start_index = i + 1
            break

    if start_index is None:
        print(f"Error: The line 'Spectrum in [nm]' was not found in the file '{input_file}'.")
        return
    
    relevant_data = []
    for line in lines[start_index:]:
        try:
            wavelength, intensity = line.strip().split(';')
            wavelength = float(wavelength.replace(",", "."))
            intensity = float(intensity.replace(",", "."))
            relevant_data.append({'wavelength': wavelength, 'intensity': intensity})
        except (ValueError, IndexError):
            continue

    min_intensity = min(item['intensity'] for item in relevant_data)
    max_intensity = max(item['intensity'] for item in relevant_data)

    indexed_data = [{'wavelength': item['wavelength'], 'intensity': item['intensity'] / max_intensity} for item in relevant_data]

    with open(output_file, 'w') as yaml_file:
        yaml.dump(indexed_data, yaml_file, default_flow_style=False)
    print(f"YAML file successfully written to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python convert_spectra_format.py <input_csv_file>")
        sys.exit(1)

    input_csv = sys.argv[1]
    convert_csv_to_yaml(input_csv)
