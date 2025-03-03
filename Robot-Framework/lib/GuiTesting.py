# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from pyscreeze import locate, center
import logging
import subprocess

class GuiTesting:

    def __init__(self, gui_temp_dir):
        self.gui_temp_dir = gui_temp_dir

    def locate_image(self, image, confidence):
        logging.info("Searching " + image)
        screenshot = self.gui_temp_dir + "screenshot.png"
        image_box = locate(image, screenshot, confidence=confidence)
        image_center = center(image_box)
        logging.info(image_box)
        logging.info(image_center)
        image_center_in_mouse_coordinates = self.convert_resolution(image_center)
        logging.info(image_center_in_mouse_coordinates)
        return image_center_in_mouse_coordinates
    
    def convert_resolution(self, coordinates):
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
    
    def convert_app_icon(self, crop, background, input_file='icon.svg', output_file='icon.png'):
        if background != "none":
            subprocess.run(['magick', '-background', background, input_file, '-gravity', 'center', '-extent',
                            '{}x{}'.format(crop, crop), output_file])
        else:
            subprocess.run(['magick', input_file, '-gravity', 'center', '-extent',
                            '{}x{}'.format(crop, crop), output_file])
        return
    
    def negate_app_icon(self, input_file, output_file):
        subprocess.run(['magick', input_file, '-negate', output_file])
