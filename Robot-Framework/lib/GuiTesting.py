# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from evdev import ecodes
from PIL import Image
from pyscreeze import locate, center
import logging
import pytesseract
import re
import subprocess

def locate_image(screenshot, image, confidence):
    logging.info("Searching " + image)
    image_box = locate(image, screenshot, confidence=confidence)
    image_center = center(image_box)
    logging.info(image_box)
    logging.info(image_center)
    image_center_in_mouse_coordinates = convert_resolution(image_center)
    logging.info(image_center_in_mouse_coordinates)
    return image_center_in_mouse_coordinates

def get_data_from_image(image, scale=1):
    image = Image.open(image)
    image = image.resize((image.width * scale, image.height * scale), Image.BICUBIC)
    data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
    logging.info(data)
    return data

def get_text(data: pytesseract.Output.DICT):
    text_list = []
    sentence = []

    for word in data['text']:
        if word == "":
            if sentence:
                text_list.append(' '.join(sentence))
                sentence.clear()
        else:
            sentence.append(word)

    if sentence:
        text_list.append(' '.join(sentence))

    logging.info(text_list)
    return text_list

def _normalize_ocr_text(text):
    # OCR can add punctuation or split words oddly. Normalize labels before matching.
    return re.sub(r"[^a-z0-9]+", "", text.lower())

def _get_ocr_words(data):
    # Keep each recognized word together with its position so field values can be read by layout.
    words = []
    for i, text in enumerate(data['text']):
        text = text.strip()
        if not text:
            continue

        words.append({
            'text': text,
            'normalized': _normalize_ocr_text(text),
            'left': data['left'][i],
            'top': data['top'][i],
            'width': data['width'][i],
            'height': data['height'][i],
        })

    return words

def get_text_field_from_image(image, field, scale=1):
    # Read table-like UI rows where the label is on the left and the value is on the same row to the right.
    logging.info(f"Reading field '{field}' from {image}")
    data = get_data_from_image(image, scale)
    words = _get_ocr_words(data)
    expected_words = [_normalize_ocr_text(word) for word in field.split()]

    for i in range(len(words)):
        label_words = words[i:i + len(expected_words)]
        if len(label_words) != len(expected_words):
            continue

        label_text = [word['normalized'] for word in label_words]
        if label_text != expected_words:
            continue

        label_right = max(word['left'] + word['width'] for word in label_words)
        label_center_y = sum(word['top'] + word['height'] / 2 for word in label_words) / len(label_words)
        label_height = max(word['height'] for word in label_words)
        row_tolerance = max(20, label_height)

        # The value is expected to be horizontally after the label and vertically aligned with it.
        value_words = [
            word for word in words
            if word['left'] > label_right
            and abs((word['top'] + word['height'] / 2) - label_center_y) <= row_tolerance
        ]
        value_words.sort(key=lambda word: word['left'])

        if value_words:
            value = ' '.join(word['text'] for word in value_words)
            logging.info(f"Field '{field}' value: {value}")
            return value

    recognized_text = get_text(data)
    raise AssertionError(f"Field '{field}' not found in image. Recognized text: {recognized_text}")

def is_text_on_the_screen(screenshot, text, scale=1):
    logging.info("Searching " + text)
    data = get_data_from_image(screenshot, scale)

    for sentence in get_text(data):
        if text in sentence:
            return True

    return False

def is_image_on_the_screen(screenshot, image, confidence=0.99):
    logging.info("Searching " + image)
    return locate(image, screenshot, confidence=confidence) is not None

def locate_text(screenshot, text, scale=1):
    logging.info("Searching " + text)
    data = get_data_from_image(screenshot, scale)

    # Loop through results to find matching text
    for i, word in enumerate(data['text']):
        if text.lower() in word.strip().lower():
            x, y, w, h = (data[key][i] for key in ['left', 'top', 'width', 'height'])
            x, y, w, h = (v // scale for v in (x, y, w, h))
            text_center = (x + w // 2, y + h // 2)
            logging.info(f"Found '{text}' at {text_center}")
            image_center_in_mouse_coordinates = convert_resolution(text_center)
            logging.info(image_center_in_mouse_coordinates)
            return image_center_in_mouse_coordinates

    raise AssertionError(f"Text '{text}' not found on screen.")

def convert_resolution(coordinates):
    # Currently default screenshot image resolution is 1920x1200
    # but ydotool mouse movement resolution was tested to be 960x600.
    # Testing shows that this scaling ratio stays fixed even if changing the display resolution:
    # ydotool mouse resolution changes in relation to display resolution.
    # Hence we can use the hardcoded value.
    scaling_factor = 2
    mouse_coordinates = {
        'x': int(coordinates[0] / scaling_factor),
        'y': int(coordinates[1] / scaling_factor)
    }
    return mouse_coordinates

def convert_app_icon(crop, background, input_file='icon.svg', output_file='icon.png'):
    if background != "none":
        subprocess.run(['magick', '-background', background, input_file, '-gravity', 'center', '-extent',
                        '{}x{}'.format(crop, crop), output_file])
    else:
        subprocess.run(['magick', input_file, '-gravity', 'center', '-extent',
                        '{}x{}'.format(crop, crop), output_file])
    return

def negate_app_icon(input_file, output_file):
    subprocess.run(['magick', input_file, '-negate', output_file])

def generate_ydotool_key_command(key_combination):
    # Returns a `key ...` command string for the given key combination,
    # e.g. generate_ydotool_key_command("LEFTMETA+LEFTSHIFT+ESC") -> 'key 125:1 42:1 1:1 1:0 42:0 125:0'
    keys = key_combination.split("+")
    key_codes = []
    for key in keys:
        key = key.strip().upper()
        full_key = f"KEY_{key}"
        if not hasattr(ecodes, full_key):
            raise ValueError(f"Unknown key: {key} (tried {full_key})")
        key_codes.append(getattr(ecodes, full_key))

    press_events = [f"{code}:1" for code in key_codes]
    release_events = [f"{code}:0" for code in reversed(key_codes)]

    return "key " + " ".join(press_events + release_events)
