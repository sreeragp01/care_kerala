from django.urls import path
from .views import SpeechToTextView, PatientSummaryView, NaturalQueryView

urlpatterns = [
    path('speech-to-text/', SpeechToTextView.as_view(), name='ai_speech_to_text'),
    path('patient-summary/<int:patient_id>/', PatientSummaryView.as_view(), name='ai_patient_summary'),
    path('natural-query/', NaturalQueryView.as_view(), name='ai_natural_query'),
]
