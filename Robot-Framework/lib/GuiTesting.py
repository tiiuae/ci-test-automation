# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from evdev import ecodes
from PIL import Image
from pyscreeze import locate, center
from rapidfuzz import fuzz
from robot.libraries.BuiltIn import BuiltIn
import logging
import pytesseract
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

def text_matches(text, substring_to_find, ignore_case=True, precision=100):
    substring_to_find = substring_to_find.lower() if ignore_case else substring_to_find
    text_to_search = text.lower() if ignore_case else text

    result = fuzz.partial_ratio_alignment(substring_to_find, text_to_search)
    precision = _parse_precision(precision)
    matched_text = text[result.dest_start:result.dest_end]
    logging.info(f"Searching for '{substring_to_find}'; Best match: '{matched_text}'; Score: {result.score}%; Precision: {precision}%.")
    _log_imperfect_text_match(substring_to_find, matched_text, result.score, precision)
    return result.score >= precision, matched_text

def _log_imperfect_text_match(substring_to_find, matched_text, score, precision):
    if precision <= score < 100:  # score is 100 max meaning perfect match, not logged if perfect or not matched
        message =  f"Accepted imperfect OCR match '{matched_text}' for expected text '{substring_to_find}'  with score {score}, allowed precision is {precision}%"
        BuiltIn().set_test_message(message, append=True, separator="\n")

def _normalize_ocr_text(text, ignore_case=True):
    text = ''.join(char for char in text if char.isalnum())
    return text.casefold() if ignore_case else text

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

def is_text_on_the_screen(screenshot, text, scale=1, ignore_case=True, precision=100):
    logging.info("Searching " + text)
    data = get_data_from_image(screenshot, scale)
    return is_text_in_parsed_image_data(data=data, text=text, ignore_case=ignore_case, precision=precision)

def is_text_in_parsed_image_data(data, text, ignore_case=True, precision=100):
    text_from_image = get_text(data)
    joined_text_from_image = ''.join(text_from_image)
    return text_matches(text=joined_text_from_image, substring_to_find=text, ignore_case=ignore_case, precision=precision)

def is_image_on_the_screen(screenshot, image, confidence=0.99):
    logging.info("Searching " + image)
    return locate(image, screenshot, confidence=confidence) is not None

def _parse_precision(precision):
    precision = int(precision)
    if not 0 <= precision <= 100:
        raise ValueError(f"precision must be between 0 and 100, {precision} was passed")
    return precision

def _find_best_ocr_match(words, text, precision, ignore_case):
    expected = _normalize_ocr_text(text, ignore_case)
    expected_word_count = max(1, len(text.split()))

    max_window_size = min(len(words), expected_word_count + 2)
    best_match = None
    best_score = -1

    for window_size in range(1, max_window_size + 1):
        for i in range(len(words) - window_size + 1):
            candidate_words = words[i:i + window_size]
            candidate_text = ' '.join(word['text'] for word in candidate_words)
            candidate = _normalize_ocr_text(candidate_text, ignore_case)
            if  candidate:
                if len(candidate) >= len(expected):
                    score = fuzz.partial_ratio(expected, candidate)
                else:
                    score = fuzz.ratio(expected, candidate)
                if score > best_score:
                    best_score = score
                    best_match = candidate_words, candidate_text

    if best_match is None or best_score < precision:
        raise AssertionError(
            f"Text '{text}' not found on screen. "
            f"Best match score: {best_score:.1f}%"
        )

    matched_words, matched_text = best_match
    return matched_words, matched_text, best_score

def locate_text(screenshot, text, scale=1, precision=100, ignore_case=True):
    logging.info(f"Searching for '{text}'")
    precision = _parse_precision(precision)
    data = get_data_from_image(screenshot, scale)
    words = _get_ocr_words(data)

    matched_words, matched_text, best_score = _find_best_ocr_match(
        words=words,text=text,precision=precision, ignore_case=ignore_case
    )

    left = min(word['left'] for word in matched_words)
    top = min(word['top'] for word in matched_words)
    right = max(word['left'] + word['width'] for word in matched_words)
    bottom = max(word['top'] + word['height'] for word in matched_words)

    x = left // scale
    y = top // scale
    w = (right - left) // scale
    h = (bottom - top) // scale
    text_center = (x + w // 2, y + h // 2)

    logging.info(
        f"Looking for '{text}' with precision {precision}%. "
        f"Best match: '{matched_text}'; Score: {best_score:.1f}%; "
        f"Location: {text_center}"
    )
    _log_imperfect_text_match(text, matched_text, best_score, precision)
    return convert_resolution(text_center)

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

def convert_app_icon(crop, background, resize='none', input_file='icon.svg', output_file='icon.png'):
    command = ['magick']
    if background != "none":
        command.extend(['-background', background])
    command.append(input_file)
    if resize != "none":
        command.extend(['-resize', resize])
    command.extend(['-gravity', 'center', '-extent', '{}x{}'.format(crop, crop), output_file])
    subprocess.run(command)
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
