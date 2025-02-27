# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import google.generativeai as genai

class GeminiImageAnalyzer:
    def __init__(self, api_key: str):
        self.api_key = api_key
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel("gemini-pro-vision")

    def analyze_image(self, image_path: str) -> str:
        try:
            with open(image_path, "rb") as img_file:
                image_bytes = img_file.read()

            response = self.model.generate_content(
                ["If screenshot contains only black screen with date and time, return 'lock screen'. Otherwise, describe what is on the screen."],
                image=[image_bytes]
            )

            return response.text if response else "No response from API"

        except Exception as e:
            return f"Error: {str(e)}"
