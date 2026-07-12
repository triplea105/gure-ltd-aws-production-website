const quoteForm = document.querySelector(".quote-form");
const catalogFilters = document.querySelectorAll(".catalog-filter");
const catalogCards = document.querySelectorAll(".product-card");
const catalogSearch = document.querySelector("[data-catalog-search]");
const catalogEmpty = document.querySelector("[data-catalog-empty]");

if (catalogCards.length > 0) {
  let activeCategory = "all";

  const updateCatalog = () => {
    const searchTerm = catalogSearch ? catalogSearch.value.trim().toLowerCase() : "";
    let visibleCount = 0;

    catalogCards.forEach((card) => {
      const categoryMatches = activeCategory === "all" || card.dataset.category === activeCategory;
      const searchMatches = !searchTerm || card.dataset.name.includes(searchTerm);
      const isVisible = categoryMatches && searchMatches;

      card.hidden = !isVisible;
      if (isVisible) {
        visibleCount += 1;
      }
    });

    if (catalogEmpty) {
      catalogEmpty.hidden = visibleCount > 0;
    }
  };

  catalogFilters.forEach((filter) => {
    filter.addEventListener("click", () => {
      activeCategory = filter.dataset.category;

      catalogFilters.forEach((button) => button.classList.remove("is-active"));
      filter.classList.add("is-active");
      updateCatalog();
    });
  });

  if (catalogSearch) {
    catalogSearch.addEventListener("input", updateCatalog);
  }
}

if (quoteForm) {
  const selectedService = new URLSearchParams(window.location.search).get("service");
  const serviceSelect = quoteForm.querySelector("[name='service_requested']");

  if (selectedService && serviceSelect) {
    serviceSelect.value = selectedService;
  }

  quoteForm.addEventListener("submit", async (event) => {
    event.preventDefault();

    const apiBaseUrl = window.GURE_API_BASE_URL;
    if (!apiBaseUrl) {
      alert("API configuration is not available yet.");
      return;
    }

    const formData = new FormData(quoteForm);
    const service = formData.get("service_requested");
    const payload = {
      request_type: requestTypeForService(service),
      category: categoryForService(service),
      service_requested: service,
      full_name: formData.get("full_name"),
      email: formData.get("email") || "",
      phone_number: formData.get("phone_number"),
      location: formData.get("location"),
      message: formData.get("message"),
    };

    try {
      const response = await fetch(`${apiBaseUrl}/requests`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        throw new Error("Request failed");
      }

      quoteForm.reset();
      alert("Your request has been submitted.");
    } catch (error) {
      alert("We could not submit your request. Please try again later.");
    }
  });
}

function requestTypeForService(service) {
  const requestTypes = {
    logistics: "logistics_request",
    vehicle_hire: "vehicle_hire_request",
    materials: "hardware_material_request",
    general_enquiry: "general_enquiry",
  };

  return requestTypes[service] || "general_enquiry";
}

function categoryForService(service) {
  const categories = {
    logistics: "logistics",
    vehicle_hire: "vehicle_hire",
    materials: "hardware_materials",
    general_enquiry: "general",
  };

  return categories[service] || "general";
}
