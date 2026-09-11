# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from evdev import ecodes
from PIL import Image
from pyscreeze import locate, center
from robot.libraries.BuiltIn import BuiltIn, RobotNotRunningError
import logging
import math
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

def text_matches(candidate, expected_text, allowed_error_percent=0, log_imperfect_match=True):
    # Public Robot keyword for fuzzy comparison of already extracted OCR text values.
    allowed_error_percent = _parse_allowed_error_percent(allowed_error_percent)
    if not allowed_error_percent:
        return candidate.strip().lower() == expected_text.strip().lower()

    matched_text = _get_fuzzy_match_text(candidate, expected_text, allowed_error_percent)
    matches = matched_text is not None
    if matches and log_imperfect_match:
        _log_imperfect_text_match(candidate, expected_text, allowed_error_percent, matched_text)

    return matches

def _normalize_ocr_text(text):
    # OCR can add punctuation or split words oddly. Normalize labels before matching.
    return re.sub(r"[^a-z0-9]+", "", text.lower())

def _normalize_ocr_text_with_map(text):
    # Keep indexes so fuzzy match spans can be reported using the original OCR text.
    normalized = []
    index_map = []
    for i, char in enumerate(text):
        if char.isalnum():
            normalized.append(char.lower())
            index_map.append(i)

    return ''.join(normalized), index_map

def _levenshtein_distance(haystack, needle):
    # Standard Levenshtein edit distance using a two-row dynamic programming table.
    # Calculates how many single-character edits are needed to turn one string into the other.
    # Allowed edits are:
    #   - insert a character
    #   - delete a character
    #   - replace a character
    if haystack == needle:
        return 0
    previous_row = list(range(len(needle) + 1))
    for i, haystack_char in enumerate(haystack, 1):
        current_row = [i]
        for j, needle_char in enumerate(needle, 1):
            insert_cost = current_row[j - 1] + 1
            delete_cost = previous_row[j] + 1
            replace_cost = previous_row[j - 1] + (haystack_char != needle_char)
            current_row.append(min(insert_cost, delete_cost, replace_cost))
        previous_row = current_row
    return previous_row[-1]

def _parse_allowed_error_percent(allowed_error_percent):
    # Robot arguments arrive as strings, so validate and convert the percentage once.
    allowed_error_percent = float(allowed_error_percent)
    if allowed_error_percent < 0 or allowed_error_percent > 100:
        raise ValueError("allowed_error_percent must be between 0 and 100")

    return allowed_error_percent

def _find_fuzzy_match_span(haystack, needle, max_errors):
    # Prefer exact substring matches; they are accepted even when fuzzy matching is disabled.
    exact_start = haystack.find(needle)
    if exact_start >= 0:
        return exact_start, exact_start + len(needle)

    # Without tolerance, empty input, or empty expected text, there is no fuzzy match to search.
    if max_errors == 0 or not haystack or not needle:
        return None

    # OCR may add or drop characters, so compare substrings slightly shorter and longer than expected.
    min_length = max(1, len(needle) - max_errors)
    max_length = min(len(haystack), len(needle) + max_errors)

    # If OCR produced fewer characters than the shortest expected candidate, compare all of it once.
    if len(haystack) < min_length:
        if _levenshtein_distance(haystack, needle) <= max_errors:
            return 0, len(haystack)
        return None

    # Return the closest acceptable substring so reports show only the matched OCR text.
    best_match = None
    best_distance = max_errors + 1
    for start in range(len(haystack)):
        for length in range(min_length, max_length + 1):
            end = start + length
            if end > len(haystack):
                break
            distance = _levenshtein_distance(haystack[start:end], needle)
            if distance < best_distance:
                best_match = (start, end)
                best_distance = distance

    return best_match

def _get_fuzzy_match_text(detected_text, expected_text, allowed_error_percent):
    # Return the original OCR substring that satisfied fuzzy matching, for readable reporting.
    expected = _normalize_ocr_text(expected_text)
    if not expected:
        return ""

    detected, index_map = _normalize_ocr_text_with_map(detected_text)
    max_errors = math.ceil(len(expected) * allowed_error_percent / 100)
    match_span = _find_fuzzy_match_span(detected, expected, max_errors)
    if match_span is None:
        return None

    start, end = match_span
    if not index_map:
        return detected_text

    return detected_text[index_map[start]:index_map[end - 1] + 1]

def _log_imperfect_text_match(detected_text, expected_text, allowed_error_percent, matched_text=None):
    # Report accepted fuzzy OCR match both via logs and Robot test message.
    if matched_text is None:
        matched_text = _get_fuzzy_match_text(detected_text, expected_text, allowed_error_percent)
    if matched_text is None:
        return

    expected = _normalize_ocr_text(expected_text)
    matched = _normalize_ocr_text(matched_text)
    if allowed_error_percent and expected != matched:
        message = (
            f"Accepted imperfect OCR match '{matched_text}' for expected text '{expected_text}' "
            f"with allowed_error_percent={allowed_error_percent:g}"
        )
        logging.info(message)
        try:
            BuiltIn().set_test_message(message, append=True, separator="\n")
        except (RuntimeError, RobotNotRunningError) as error:
            logging.debug(f"Could not append OCR match to Robot test message: {error}")

def _get_ocr_word_candidates(words, text, allowed_error_percent):
    # Build adjacent OCR word groups so multi-word labels can match across Tesseract word splits.
    expected_word_count = max(1, len(text.split()))
    max_window_size = expected_word_count if allowed_error_percent == 0 else expected_word_count + 2

    for window_size in range(1, max_window_size + 1):
        for i in range(0, len(words) - window_size + 1):
            candidate_words = words[i:i + window_size]
            yield {
                'text': ' '.join(word['text'] for word in candidate_words),
                'left': min(word['left'] for word in candidate_words),
                'top': min(word['top'] for word in candidate_words),
                'right': max(word['left'] + word['width'] for word in candidate_words),
                'bottom': max(word['top'] + word['height'] for word in candidate_words),
            }

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

def is_text_on_the_screen(screenshot, text, scale=1, compare_alphanum_only=False, allowed_error_percent=0):
    logging.info("Searching " + text)
    data = get_data_from_image(screenshot, scale)
    expected_text = text
    text_entries = get_text(data)
    text_from_image = ''.join(text_entries)
    allowed_error_percent = _parse_allowed_error_percent(allowed_error_percent)

    if compare_alphanum_only:
        text_from_image = ''.join(char for char in text_from_image if char.isalnum())
        text = ''.join(char for char in text if char.isalnum())

    if allowed_error_percent:
        for text_entry in text_entries:
            matched_text = _get_fuzzy_match_text(text_entry, expected_text, allowed_error_percent)
            if matched_text is not None:
                _log_imperfect_text_match(text_entry, expected_text, allowed_error_percent, matched_text)
                return True

        matched_text = _get_fuzzy_match_text(text_from_image, expected_text, allowed_error_percent)
        if matched_text is not None:
            _log_imperfect_text_match(text_from_image, expected_text, allowed_error_percent, matched_text)
            return True

        return False

    return text in text_from_image

def is_image_on_the_screen(screenshot, image, confidence=0.99):
    logging.info("Searching " + image)
    return locate(image, screenshot, confidence=confidence) is not None

def locate_text(screenshot, text, scale=1, allowed_error_percent=0):
    logging.info("Searching " + text)
    data = get_data_from_image(screenshot, scale)
    allowed_error_percent = _parse_allowed_error_percent(allowed_error_percent)
    words = _get_ocr_words(data)

    for candidate in _get_ocr_word_candidates(words, text, allowed_error_percent):
        matched_text = _get_fuzzy_match_text(candidate['text'], text, allowed_error_percent)
        if matched_text is not None:
            _log_imperfect_text_match(candidate['text'], text, allowed_error_percent, matched_text)
            x = candidate['left'] // scale
            y = candidate['top'] // scale
            w = (candidate['right'] - candidate['left']) // scale
            h = (candidate['bottom'] - candidate['top']) // scale
            text_center = (x + w // 2, y + h // 2)
            logging.info(f"Found '{text}' as '{candidate['text']}' at {text_center}")
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
