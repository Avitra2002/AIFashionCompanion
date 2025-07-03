from django.urls import path
from .views.classify import ClassifyClothingView
from .views.save_to_closet import SaveClothingItemView
from .views.get_clothes import GetClothingItemsView

urlpatterns = [
    path('classify/', ClassifyClothingView.as_view(), name='classify'),
    path('closet-items/', SaveClothingItemView.as_view(), name='save-closet-items'), 
    path('closet-items/all/', GetClothingItemsView.as_view(), name='get-closet-items'),
]
