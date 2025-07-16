from django.urls import path

from .views.chat import OllamaChatView

from .views.update import UpdateClothingItemView
from .views.classify import ClassifyClothingView
from .views.save_to_closet import SaveClothingItemView
from .views.get_clothes import GetClothingItemsView

urlpatterns = [
    path('classify/', ClassifyClothingView.as_view(), name='classify'),
    path('closet-items/', SaveClothingItemView.as_view(), name='save-closet-items'), 
    path('closet-items/all/', GetClothingItemsView.as_view(), name='get-closet-items'),
    path('closet-items/<str:item_id>/', UpdateClothingItemView.as_view(), name='update-closet-item'),
    path('chat/', OllamaChatView.as_view(), name='ollama-chat'),
]
