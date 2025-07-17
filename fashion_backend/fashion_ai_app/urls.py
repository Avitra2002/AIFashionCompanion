from django.urls import path

from .views.chat import FashionLookChatView

from .views.update import UpdateClothingItemView
from .views.classify import ClassifyClothingView
from .views.save_to_closet import SaveClothingItemView
from .views.get_clothes import GetClothingItemsView
from .views.save_look import SaveLookView
urlpatterns = [
    path('classify/', ClassifyClothingView.as_view(), name='classify'),
    path('closet-items/', SaveClothingItemView.as_view(), name='save-closet-items'), 
    path('closet-items/all/', GetClothingItemsView.as_view(), name='get-closet-items'),
    path('closet-items/<str:item_id>/', UpdateClothingItemView.as_view(), name='update-closet-item'),
    path('chat/', FashionLookChatView.as_view(), name='fashion-chat'),
    path('save_look/', SaveLookView.as_view(), name='save-look'),
]
