from django.urls import path
from .views.classify import ClassifyClothingView
from .views.save_to_closet import SaveClothingItemView

urlpatterns = [
    path('classify/', ClassifyClothingView.as_view(), name='classify'),
    path('closet-items/', SaveClothingItemView.as_view(), name='closet-items'),  # 👈 add this
]
