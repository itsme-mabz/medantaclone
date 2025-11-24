from django.shortcuts import render

# Create your views here.

def home(request):
    """
    Main homepage view
    """
    return render(request, 'base/index.html')

# Add more views here as needed
def about(request):
    return render(request, 'base/about.html')

# def contact(request):
#     return render(request, 'base/contact.html')
