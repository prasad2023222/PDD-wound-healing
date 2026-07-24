import base64
import json
import re
from pathlib import Path

import requests


OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "qwen2.5vl:3b"


def extract_json(text: str):
    try:
        return json.loads(text)
    except Exception:
        pass

    match = re.search(r"\{.*\}", text, re.DOTALL)

    if not match:
        return None

    try:
        return json.loads(match.group())
    except Exception:
        return None


def image_to_base64(image_path: str):
    image_bytes = Path(image_path).read_bytes()
    return base64.b64encode(image_bytes).decode("utf-8")


def clamp_number(value, minimum=0, maximum=100):
    try:
        number = int(value)
    except Exception:
        number = minimum

    return max(minimum, min(maximum, number))


def normalize_list(value):
    if isinstance(value, list):
        return [str(item) for item in value]

    if isinstance(value, str) and value.strip():
        return [value]

    return []


def fallback_analysis():
    return {
        "condition": "Possible smoker's palate irritation",
        "severity": "Low",
        "healing_score": 65,
        "confidence": 70,
        "progress_status": "AI unavailable",
        "summary": "AI analysis is temporarily unavailable. A safe fallback assessment was generated.",
        "observations": [
            "Image uploaded successfully",
            "Local AI model was unavailable",
            "Manual clinical review is recommended if symptoms persist"
        ],
        "recommendations": [
            "Avoid smoking during healing",
            "Stay hydrated",
            "Maintain oral hygiene",
            "Consult a dentist for clinical evaluation"
        ],
        "improvement_percentage": 0,
        "predicted_recovery_days": 14,
        "risk_alert": "AI model unavailable. Seek professional review if symptoms persist.",
        "coaching_tip": "Continue tracking with clear images and daily logs."
    }


def unclear_analysis():
    return {
        "condition": "Unclear",
        "severity": "Unclear",
        "healing_score": 0,
        "confidence": 0,
        "progress_status": "Unclear",
        "summary": "The image could not be analyzed clearly.",
        "observations": [
            "Image analysis was inconclusive"
        ],
        "recommendations": [
            "Retake the image with better lighting",
            "Consult a dentist for clinical evaluation"
        ],
        "improvement_percentage": 0,
        "predicted_recovery_days": None,
        "risk_alert": "Image clarity is insufficient for a reliable wellness assessment.",
        "coaching_tip": "Retake the image in bright lighting with the palate clearly visible."
    }


def post_process_analysis(parsed: dict, previous_analysis: dict | None = None):
    previous_score = None

    if previous_analysis:
        previous_score = previous_analysis.get("healing_score")

    healing_score = clamp_number(parsed.get("healing_score", 0))
    confidence = clamp_number(parsed.get("confidence", 0))

    if previous_score is not None:
        try:
            previous_score = int(previous_score)
            improvement_percentage = healing_score - previous_score
        except Exception:
            improvement_percentage = 0
    else:
        improvement_percentage = 0

    if previous_score is None:
        progress_status = "First scan"
    else:
        if improvement_percentage > 5:
            progress_status = "Improving"
        elif improvement_percentage < -5:
            progress_status = "Worsening"
        else:
            progress_status = "Stable"

    severity = parsed.get("severity", "Unclear")

    if severity not in ["Low", "Medium", "High", "Unclear"]:
        if healing_score >= 75:
            severity = "Low"
        elif healing_score >= 45:
            severity = "Medium"
        else:
            severity = "High"

    predicted_recovery_days = parsed.get("predicted_recovery_days")

    if predicted_recovery_days is None:
        if healing_score >= 85:
            predicted_recovery_days = 3
        elif healing_score >= 70:
            predicted_recovery_days = 7
        elif healing_score >= 50:
            predicted_recovery_days = 14
        elif healing_score > 0:
            predicted_recovery_days = 21
        else:
            predicted_recovery_days = None

    observations = normalize_list(parsed.get("observations"))
    recommendations = normalize_list(parsed.get("recommendations"))

    if not observations:
        observations = [
            "Palate image was processed by the local vision model",
            "Visual findings should be interpreted as wellness guidance only"
        ]

    if not recommendations:
        recommendations = [
            "Avoid smoking during healing",
            "Maintain oral hygiene",
            "Stay hydrated",
            "Consult a dentist if symptoms persist or worsen"
        ]

    risk_alert = parsed.get("risk_alert")

    if not risk_alert:
        if progress_status == "Worsening":
            risk_alert = "The latest scan appears worse than the previous scan. Consider professional dental review."
        elif severity == "High":
            risk_alert = "High irritation pattern detected visually. A dental consultation is recommended."
        else:
            risk_alert = "No urgent visual warning detected, but continue monitoring."

    coaching_tip = parsed.get("coaching_tip")

    if not coaching_tip:
        if progress_status == "Improving":
            coaching_tip = "Your scan trend appears to be improving. Continue avoiding smoking and stay hydrated."
        elif progress_status == "Worsening":
            coaching_tip = "Try to avoid smoke exposure and track symptoms closely over the next few days."
        else:
            coaching_tip = "Keep taking scans under similar lighting to improve trend accuracy."

    summary = parsed.get("summary")

    if not summary:
        summary = (
            f"Latest visual assessment suggests {severity.lower()} irritation "
            f"with a healing score of {healing_score}/100."
        )

    return {
        "condition": parsed.get(
            "condition",
            "Possible smoker's palate irritation"
        ),
        "severity": severity,
        "healing_score": healing_score,
        "confidence": confidence,
        "progress_status": progress_status,
        "summary": summary,
        "observations": observations,
        "recommendations": recommendations,
        "improvement_percentage": improvement_percentage,
        "predicted_recovery_days": predicted_recovery_days,
        "risk_alert": risk_alert,
        "coaching_tip": coaching_tip
    }


def analyze_palate_image(
    current_image_path: str,
    previous_image_path: str | None = None,
    previous_analysis: dict | None = None
):
    current_image_base64 = image_to_base64(current_image_path)

    prompt = """
You are an AI assistant inside an oral health tracking app.

Context:
The user is tracking smoker's palate / nicotinic stomatitis recovery over time using palate images.

Important safety rules:
- Do NOT claim to diagnose disease.
- This is only an AI-assisted visual wellness assessment.
- Encourage dental consultation for persistent, worsening, painful, bleeding, or unclear lesions.
- Return ONLY valid JSON. No markdown. No explanation outside JSON.

Analyze the palate image and produce recovery intelligence.

Scoring:
healing_score: 0 to 100
0 = severe irritation / poor healing appearance
100 = healthy-looking / recovered appearance

confidence: 0 to 100
This means confidence in the visual assessment, not medical certainty.

Return JSON exactly like this:

{
  "condition": "string",
  "severity": "Low | Medium | High | Unclear",
  "healing_score": 0,
  "confidence": 0,
  "progress_status": "Improving | Stable | Worsening | First scan | Unclear",
  "summary": "short natural user-friendly summary",
  "observations": ["visual observation 1", "visual observation 2", "visual observation 3"],
  "recommendations": ["action 1", "action 2", "action 3"],
  "improvement_percentage": 0,
  "predicted_recovery_days": 0,
  "risk_alert": "short risk alert",
  "coaching_tip": "personalized coaching tip"
}
"""

    images = [current_image_base64]

    if previous_image_path:
        previous_image_base64 = image_to_base64(previous_image_path)

        prompt += f"""

Previous scan analysis:
{json.dumps(previous_analysis or {}, default=str)}

You are receiving two images:
Image 1 = previous scan
Image 2 = latest scan

Compare them carefully and determine:
- whether redness/irritation appears reduced, similar, or worse
- whether white patches/texture look improved or worse
- whether healing_score should increase or decrease
- whether progress_status should be Improving, Stable, or Worsening

Do not exaggerate. If unsure, use Stable or Unclear.
"""

        images = [
            previous_image_base64,
            current_image_base64,
        ]

    payload = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "images": images,
        "stream": False,
        "options": {
            "temperature": 0.2
        }
    }

    try:
        response = requests.post(
            OLLAMA_URL,
            json=payload,
            timeout=300,
        )

        print("Ollama status:", response.status_code)

        response.raise_for_status()

        data = response.json()

        model_text = data.get("response", "")

        print("Ollama raw response:", model_text)

        parsed = extract_json(model_text)

        if parsed is None:
            return unclear_analysis()

        return post_process_analysis(
            parsed,
            previous_analysis=previous_analysis
        )

    except Exception as e:
        import traceback

        print("\n========== OLLAMA ERROR ==========")
        print(str(e))
        traceback.print_exc()
        print("==================================\n")

        return fallback_analysis()