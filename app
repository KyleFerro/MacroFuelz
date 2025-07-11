// MacroFuel - Nutrition Tracker JavaScript

// Global variables
let dailyData = {
  consumed: {
    calories: 0,
    protein: 0,
    carbs: 0,
    fats: 0
  },
  goals: {
    calories: 2000,
    protein: 150,
    carbs: 250,
    fats: 67
  },
  meals: []
};

// Store all daily data, keyed by date string (YYYY-MM-DD)
let allDailyData = {};

let currentMonth = new Date().getMonth();
let currentYear = new Date().getFullYear();

// Check if localStorage is available
const isLocalStorageAvailable = (() => {
  try {
    const test = '__localStorage_test__';
    localStorage.setItem(test, test);
    localStorage.removeItem(test);
    return true;
  } catch (e) {
    return false;
  }
})();

// Functions called on ALL pages to maintain consistent header/sidebar
document.addEventListener('DOMContentLoaded', function() {
  loadAllData(); // Load all historical data first
  loadDailyDataForToday(); // Then, load data for the current day into 'dailyData'
  
  // Set active navigation tab based on current page
  setActiveNavTab();

  // Only update daily tracker specific elements if on index.html
  if (document.getElementById('tracker')) {
    updateDisplay(); // Updates calories, macros, and meals list
  }
  
  updateQuickStats(); // Update quick stats from any page
  
  // Initialize monthly checklist if on that page
  if (document.querySelector('.checklist-grid')) {
    displayMonthlyChecklist(currentMonth, currentYear);
  }

  // Initialize day result if on that page
  if (document.getElementById('dayResultDisplay')) {
    const urlParams = new URLSearchParams(window.location.search);
    const date = urlParams.get('date');
    if (date) {
      displayDayResult(date);
    }
  }

  // Save current day's data every 30 seconds if localStorage is available
  if (isLocalStorageAvailable) {
    setInterval(saveDailyDataForToday, 30000); // Save current day's data every 30 seconds
  }
});

// Sidebar functions
function toggleSidebar() {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('overlay');
  if (sidebar && overlay) {
    sidebar.classList.toggle('active');
    overlay.style.display = sidebar.classList.contains('active') ? 'block' : 'none';
  }
}

// Sets the active class on the correct navigation tab
function setActiveNavTab() {
  const path = window.location.pathname;

  // Select all main navigation tabs (if they exist on the current page)
  const mainNavTabs = [
    document.getElementById('navDailyTracker'),
    document.getElementById('navMonthlyProgress'),
    document.getElementById('navSubscriptions'),
    document.getElementById('navDayChosen')
  ].filter(Boolean); // Filter out nulls if an ID doesn't exist on a page

  // Select all sidebar navigation links (if they exist on the current page)
  const sidebarNavLinks = [
    document.getElementById('sidebarDailyTracker'),
    document.getElementById('sidebarMonthlyProgress'),
    document.getElementById('sidebarSubscriptions'),
    document.getElementById('sidebarMedical')
  ].filter(Boolean); // Filter out nulls

  // Clear all active classes from main nav tabs
  mainNavTabs.forEach(tab => {
    tab.classList.remove('active');
    if (tab.id === 'navDayChosen') {
      tab.style.display = 'none'; // Hide specific day tab by default
    }
  });

  // Clear all active classes from sidebar links
  sidebarNavLinks.forEach(link => {
      // Ensure the 'active' class is removed from the <li> parent if it's there,
      // or directly from the <a> if the style targets the <a> itself.
      link.classList.remove('active');
      // If your sidebar active styling is on the <li>, you might need:
      // if (link.parentElement && link.parentElement.tagName === 'LI') {
      //     link.parentElement.classList.remove('active');
      // }
  });


  // Set active class for main navigation tabs and sidebar links
  if (path.includes('index.html') || path === '/') {
    const navDailyTracker = document.getElementById('navDailyTracker');
    if (navDailyTracker) navDailyTracker.classList.add('active');
    const sidebarDailyTracker = document.getElementById('sidebarDailyTracker');
    if (sidebarDailyTracker) sidebarDailyTracker.classList.add('active');
  } else if (path.includes('monthly-checklist.html')) {
    const navMonthlyProgress = document.getElementById('navMonthlyProgress');
    if (navMonthlyProgress) navMonthlyProgress.classList.add('active');
    const sidebarMonthlyProgress = document.getElementById('sidebarMonthlyProgress');
    if (sidebarMonthlyProgress) sidebarMonthlyProgress.classList.add('active');
  } else if (path.includes('subscriptions.html')) {
    const navSubscriptions = document.getElementById('navSubscriptions');
    if (navSubscriptions) navSubscriptions.classList.add('active');
    const sidebarSubscriptions = document.getElementById('sidebarSubscriptions');
    if (sidebarSubscriptions) sidebarSubscriptions.classList.add('active');
  } else if (path.includes('medical.html')) { // New case for medical.html
    const sidebarMedical = document.getElementById('sidebarMedical');
    if (sidebarMedical) sidebarMedical.classList.add('active');
  } else if (path.includes('day-result.html')) {
    const navDayChosen = document.getElementById('navDayChosen');
    if (navDayChosen) {
      navDayChosen.style.display = 'block'; // Show the specific day tab
      navDayChosen.classList.add('active');
      const urlParams = new URLSearchParams(window.location.search);
      const dateKey = urlParams.get('date');
      if (dateKey) {
        const date = new Date(dateKey);
        navDayChosen.textContent = `Day: ${date.getDate()} ${date.toLocaleString('default', { month: 'short' })}`;
      }
    }
    // For day-result, typically the 'Monthly Progress' sidebar link remains active as it's a sub-page.
    const sidebarMonthlyProgress = document.getElementById('sidebarMonthlyProgress');
    if (sidebarMonthlyProgress) sidebarMonthlyProgress.classList.add('active');
  }
}


// Settings Panel functions
function toggleSettingsPanel() {
  const settingsPanel = document.getElementById('settingsPanel');
  if (!settingsPanel) return;

  settingsPanel.classList.toggle('active'); // Toggle visibility

  // If panel is active, populate input fields with current goals
  if (settingsPanel.classList.contains('active')) {
    document.getElementById('goalCalories').value = dailyData.goals.calories;
    document.getElementById('goalProtein').value = dailyData.goals.protein;
    document.getElementById('goalCarbs').value = dailyData.goals.carbs;
    document.getElementById('goalFats').value = dailyData.goals.fats;
  }
}

function setDailyGoals() {
  const goalCaloriesInput = document.getElementById('goalCalories');
  const goalProteinInput = document.getElementById('goalProtein');
  const goalCarbsInput = document.getElementById('goalCarbs');
  const goalFatsInput = document.getElementById('goalFats');

  if (!goalCaloriesInput || !goalProteinInput || !goalCarbsInput || !goalFatsInput) {
    console.error('Cannot find all goal input fields.');
    return;
  }

  const newCalories = parseFloat(goalCaloriesInput.value) || 0;
  const newProtein = parseFloat(goalProteinInput.value) || 0;
  const newCarbs = parseFloat(goalCarbsInput.value) || 0;
  const newFats = parseFloat(goalFatsInput.value) || 0;

  if (newCalories <= 0 || newProtein <= 0 || newCarbs <= 0 || newFats <= 0) {
    alert('Please enter valid positive numbers for all goals.');
    return;
  }

  dailyData.goals.calories = newCalories;
  dailyData.goals.protein = newProtein;
  dailyData.goals.carbs = newCarbs;
  dailyData.goals.fats = newFats;

  saveDailyDataForToday(); // Save the updated goals for the current day
  updateDisplay(); // Refresh the display
  showNotification('Daily goals updated!');
  toggleSettingsPanel(); // Optionally hide the panel after saving
}


// Food management functions (primarily for index.html)
function addFood() {
  const foodNameInput = document.getElementById('foodName');
  const caloriesInput = document.getElementById('calories');
  const proteinInput = document.getElementById('protein');
  const carbsInput = document.getElementById('carbs');
  const fatsInput = document.getElementById('fats');
  
  if (!foodNameInput || !caloriesInput || !proteinInput || !carbsInput || !fatsInput) {
    console.error('Cannot find all form inputs. This function might be called on the wrong page.');
    return;
  }
  
  const foodName = foodNameInput.value.trim();
  const calories = parseFloat(caloriesInput.value) || 0;
  const protein = parseFloat(proteinInput.value) || 0;
  const carbs = parseFloat(carbsInput.value) || 0;
  const fats = parseFloat(fatsInput.value) || 0;
  
  if (!foodName) {
    alert('Please enter a food name');
    return;
  }
  
  if (calories <= 0 && (protein <= 0 && carbs <= 0 && fats <= 0)) {
    alert('Please enter valid calories or at least one macro value');
    return;
  }
  
  const meal = {
    id: Date.now(),
    name: foodName,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fats: fats,
    timestamp: new Date().toISOString()
  };
  
  dailyData.meals.push(meal);
  
  dailyData.consumed.calories += calories;
  dailyData.consumed.protein += protein;
  dailyData.consumed.carbs += carbs;
  dailyData.consumed.fats += fats;
  
  saveDailyDataForToday(); // Save today's data specifically
  updateDisplay();
  clearForm();
  
  showNotification('Food added successfully!');
}

function deleteFood(mealId) {
  const mealIndex = dailyData.meals.findIndex(meal => meal.id === mealId);
  if (mealIndex === -1) return;
  
  const meal = dailyData.meals[mealIndex];
  
  dailyData.consumed.calories -= meal.calories;
  dailyData.consumed.protein -= meal.protein;
  dailyData.consumed.carbs -= meal.carbs;
  dailyData.consumed.fats -= meal.fats;
  
  dailyData.meals.splice(mealIndex, 1);
  
  saveDailyDataForToday(); // Save today's data specifically
  updateDisplay();
  
  showNotification('Food removed successfully!');
}

function clearForm() {
  const foodNameInput = document.getElementById('foodName');
  const caloriesInput = document.getElementById('calories');
  const proteinInput = document.getElementById('protein');
  const carbsInput = document.getElementById('carbs');
  const fatsInput = document.getElementById('fats');

  if(foodNameInput) foodNameInput.value = '';
  if(caloriesInput) caloriesInput.value = '';
  if(proteinInput) proteinInput.value = '';
  if(carbsInput) carbsInput.value = '';
  if(fatsInput) fatsInput.value = '';
}

function clearAllMeals() {
  // Reset consumed values and meals, but keep goals as they are set
  dailyData.consumed = { calories: 0, protein: 0, carbs: 0, fats: 0 };
  dailyData.meals = [];
  saveDailyDataForToday();
  updateDisplay();
  showNotification('All meals cleared for today!');
}

// Display update functions (primarily for index.html)
function updateDisplay() {
  updateCaloriesDisplay();
  updateMacrosDisplay();
  updateMealsList();
  updateQuickStats(); // Ensures quick stats in header are always current
  updateSummaryStats();
}

function updateCaloriesDisplay() {
  const consumedEl = document.getElementById('consumedCalories');
  const goalEl = document.getElementById('calorieGoal');
  const remainingEl = document.getElementById('remainingCalories');

  if (consumedEl && goalEl && remainingEl) {
    const consumed = Math.round(dailyData.consumed.calories);
    const goal = dailyData.goals.calories;
    const remaining = Math.max(0, goal - consumed);
    
    consumedEl.textContent = consumed;
    goalEl.textContent = goal;
    remainingEl.textContent = remaining;
  }
}

function updateMacrosDisplay() {
  const macros = ['protein', 'carbs', 'fats'];
  macros.forEach(macro => {
    const consumedEl = document.getElementById(`consumed${macro.charAt(0).toUpperCase() + macro.slice(1)}`);
    const remainingEl = document.getElementById(`remaining${macro.charAt(0).toUpperCase() + macro.slice(1)}`);
    const progressEl = document.getElementById(`${macro}Progress`);
    if (consumedEl && remainingEl && progressEl) {
      const consumed = Math.round(dailyData.consumed[macro]);
      const goal = dailyData.goals[macro];
      const remaining = Math.max(0, goal - consumed);
      const progress = Math.min(100, (consumed / goal) * 100);
      consumedEl.textContent = consumed;
      remainingEl.textContent = remaining;
      progressEl.style.width = progress + '%';
    }
  });
}

function updateMealsList() {
  const mealsList = document.getElementById('mealsList'); // Corrected ID to match HTML
  if (!mealsList) return;

  if (dailyData.meals.length === 0) {
    mealsList.innerHTML = `
      <div class="empty-state">
        <p>No meals added yet</p>
        <p>Add your first meal using the form on the right!</p>
      </div>
    `;
  } else {
    mealsList.innerHTML = dailyData.meals.map(meal => `
      <div class="meal-item">
        <div class="meal-info">
          <div class="meal-name">${meal.name}</div>
          <div class="meal-macros">
            P: <span class="macro-protein">${Math.round(meal.protein)}g</span> • C: <span class="macro-carbs">${Math.round(meal.carbs)}g</span> • F: <span class="macro-fats">${Math.round(meal.fats)}g</span>
          </div>
        </div>
        <div class="meal-calories">${Math.round(meal.calories)} cal</div>
        <button class="delete-btn" onclick="deleteFood(${meal.id})">Delete</button>
      </div>
    `).join('');
  }
}

function updateQuickStats() {
  // Ensure we're working with the current day's data for quick stats
  // This is called after loadDailyDataForToday() on DOMContentLoaded
  const totalMeals = dailyData.meals.length;
  const calorieProgress = dailyData.goals.calories > 0 ? Math.round((dailyData.consumed.calories / dailyData.goals.calories) * 100) : 0;

  const totalMealsEl = document.getElementById('totalMeals');
  const calorieProgressEl = document.getElementById('calorieProgress');
  const streakDaysEl = document.getElementById('streakDays'); // Assuming streakDays is managed elsewhere or is a placeholder

  if (totalMealsEl) totalMealsEl.textContent = totalMeals;
  if (calorieProgressEl) calorieProgressEl.textContent = `${calorieProgress}%`;
  // streakDaysEl is not updated here, assuming it's a fixed value or updated by another function not shown
}

function updateSummaryStats() {
  // This function is for `index.html`'s summary elements.
  // It's called by `updateDisplay`.
  const summaryProteinEl = document.getElementById('summaryProtein');
  const summaryCarbsEl = document.getElementById('summaryCarbs');
  const summaryFatsEl = document.getElementById('summaryFats');

  if (summaryProteinEl) summaryProteinEl.textContent = Math.round(dailyData.consumed.protein) + 'g';
  if (summaryCarbsEl) summaryCarbsEl.textContent = Math.round(dailyData.consumed.carbs) + 'g';
  if (summaryFatsEl) summaryFatsEl.textContent = Math.round(dailyData.consumed.fats) + 'g';
}


// Local Storage functions
function saveDailyDataForToday() {
  const todayKey = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  allDailyData[todayKey] = JSON.parse(JSON.stringify(dailyData)); // Deep copy to prevent reference issues
  if (isLocalStorageAvailable) {
    localStorage.setItem('allDailyData', JSON.stringify(allDailyData));
  } else {
    showNotification('Local storage is not available. Data will not be saved.');
  }
}

function loadDailyDataForToday() {
  const todayKey = new Date().toISOString().slice(0, 10);
  if (allDailyData[todayKey]) {
    dailyData = JSON.parse(JSON.stringify(allDailyData[todayKey]));
  } else {
    // If no data for today, reset consumed and meals, but keep goals
    dailyData.consumed = { calories: 0, protein: 0, carbs: 0, fats: 0 };
    dailyData.meals = [];
    // Goals remain from initial state or last set goals
  }
}

function loadAllData() {
  if (isLocalStorageAvailable) {
    const storedData = localStorage.getItem('allDailyData');
    if (storedData) {
      allDailyData = JSON.parse(storedData);
    }
  }
}

// Notification system
function showNotification(message) {
  let notification = document.getElementById('notification');
  if (!notification) {
    notification = document.createElement('div');
    notification.id = 'notification';
    notification.classList.add('notification');
    document.body.appendChild(notification);
  }
  notification.textContent = message;
  notification.classList.add('show');
  setTimeout(() => {
    notification.classList.remove('show');
  }, 3000); // Hide after 3 seconds
}

// Monthly checklist page specific functions
function displayMonthlyChecklist(month, year) {
  const checklistGrid = document.querySelector('.checklist-grid');
  const currentMonthYearHeader = document.getElementById('currentMonthYear');
  if (!checklistGrid || !currentMonthYearHeader) return;

  currentMonth = month;
  currentYear = year;

  currentMonthYearHeader.textContent = new Date(year, month).toLocaleString('en-US', { month: 'long', year: 'numeric' });
  checklistGrid.innerHTML = ''; // Clear previous days

  const firstDayOfMonth = new Date(year, month, 1).getDay(); // 0 for Sunday, 1 for Monday, etc.
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  // Add empty placeholders for days before the 1st
  for (let i = 0; i < firstDayOfMonth; i++) {
    const emptyDiv = document.createElement('div');
    checklistGrid.appendChild(emptyDiv);
  }

  // Add days of the month
  for (let day = 1; day <= daysInMonth; day++) {
    const dateKey = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const dayData = allDailyData[dateKey];
    const hasData = dayData && (dayData.consumed.calories > 0 || dayData.meals.length > 0);

    const dayDiv = document.createElement('div');
    dayDiv.classList.add('day-checkbox');
    if (hasData) {
        dayDiv.classList.add('has-data');
    }

    // Check if it's today's date
    const today = new Date();
    const isToday = today.getFullYear() === year && today.getMonth() === month && today.getDate() === day;
    if (isToday) {
        dayDiv.classList.add('today');
    }

    dayDiv.innerHTML = `
      <input type="checkbox" id="day${day}" ${hasData ? 'checked' : ''} disabled>
      <label for="day${day}" onclick="handleDayClick('${dateKey}')">
        <span class="day-number">${day}</span>
        ${hasData ? '<span class="check-icon"></span>' : ''}
      </label>
    `;
    checklistGrid.appendChild(dayDiv);
  }
}

function changeMonth(delta) {
  currentMonth += delta;
  if (currentMonth > 11) {
    currentMonth = 0;
    currentYear++;
  } else if (currentMonth < 0) {
    currentMonth = 11;
    currentYear--;
  }
  displayMonthlyChecklist(currentMonth, currentYear);
}

function handleDayClick(dateKey) {
  // Redirect to day-result.html with the selected date
  window.location.href = `day-result.html?date=${dateKey}`;
}

// Day result page specific functions
function displayDayResult(dateKey) {
  const data = allDailyData[dateKey];
  const resultDateEl = document.getElementById('resultDate');
  const resultCaloriesEl = document.getElementById('resultCalories');
  const resultProteinEl = document.getElementById('resultProtein');
  const resultCarbsEl = document.getElementById('resultCarbs');
  const resultFatsEl = document.getElementById('resultFats');
  const resultMealsListEl = document.getElementById('resultMealsList');
  const aiSuggestedMealsEl = document.getElementById('aiSuggestedMeals'); // New element

  if (!resultDateEl || !resultCaloriesEl || !resultProteinEl || !resultCarbsEl || !resultFatsEl || !resultMealsListEl) {
    console.error("Missing elements for day result display.");
    return;
  }

  // Set active nav tab for the specific day
  const navDayChosen = document.getElementById('navDayChosen');
  if (navDayChosen) {
    navDayChosen.style.display = 'block';
    navDayChosen.textContent = `Day: ${new Date(dateKey).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}`;
    navDayChosen.classList.add('active'); // Set it active
    // Deactivate other static tabs if active
    document.getElementById('navDailyTracker').classList.remove('active');
    document.getElementById('navMonthlyProgress').classList.remove('active');
    const subscriptionsTab = document.getElementById('navSubscriptions');
    if (subscriptionsTab) subscriptionsTab.classList.remove('active');
  }


  if (data) {
    resultDateEl.textContent = new Date(dateKey).toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
    resultCaloriesEl.textContent = `${Math.round(data.consumed.calories)} kcal`;
    resultProteinEl.textContent = `${Math.round(data.consumed.protein)}g`;
    resultCarbsEl.textContent = `${Math.round(data.consumed.carbs)}g`;
    resultFatsEl.textContent = `${Math.round(data.consumed.fats)}g`;

    if (data.meals.length === 0) {
      resultMealsListEl.innerHTML = '<p class="empty-state">No meals logged for this day.</p>';
    } else {
      resultMealsListEl.innerHTML = data.meals.map(meal => `
        <div class="meal-item">
          <div class="meal-info">
            <div class="meal-name">${meal.name}</div>
            <div class="meal-macros">
              P: <span class="macro-protein">${Math.round(meal.protein)}g</span> • C: <span class="macro-carbs">${Math.round(meal.carbs)}g</span> • F: <span class="macro-fats">${Math.round(meal.fats)}g</span>
            </div>
          </div>
          <div class="meal-calories">${Math.round(meal.calories)} cal</div>
        </div>
      `).join('');
    }

    // AI Suggested Meals - Placeholder for now
    if (aiSuggestedMealsEl) {
      const remainingCalories = data.goals.calories - data.consumed.calories;
      if (remainingCalories > 0) {
        aiSuggestedMealsEl.textContent = `You have ${Math.round(remainingCalories)} calories remaining. Consider a snack like an apple and peanut butter.`;
      } else if (remainingCalories < 0) {
        aiSuggestedMealsEl.textContent = `You've exceeded your calorie goal by ${Math.abs(Math.round(remainingCalories))} calories.`;
      } else {
        aiSuggestedMealsEl.textContent = `You've hit your calorie goal!`;
      }
    }

  } else {
    resultDateEl.textContent = new Date(dateKey).toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
    resultCaloriesEl.textContent = '0 kcal';
    resultProteinEl.textContent = '0g';
    resultCarbsEl.textContent = '0g';
    resultFatsEl.textContent = '0g';
    resultMealsListEl.innerHTML = '<p class="empty-state">No data available for this day.</p>';
    if (aiSuggestedMealsEl) {
      aiSuggestedMealsEl.textContent = `No data to provide suggestions.`;
    }
  }
}

// Handle form submission with Enter key (only relevant on index.html)
document.addEventListener('keypress', function(e) {
  if (e.key === 'Enter' && e.target.tagName === 'INPUT') {
    const foodForm = e.target.closest('.add-food-form');
    if (foodForm) {
      addFood();
      return; // Prevent further processing if addFood was called
    }
    const settingsForm = e.target.closest('.settings-panel');
    if (settingsForm) {
      setDailyGoals();
      return; // Prevent further processing if setDailyGoals was called
    }
  }
});

// Make functions globally available
window.addFood = addFood;
window.deleteFood = deleteFood;
window.clearAllMeals = clearAllMeals;
window.saveDailyDataForToday = saveDailyDataForToday;
window.toggleSidebar = toggleSidebar;
window.changeMonth = changeMonth;
window.displayDayResult = displayDayResult; // Used by day-result.html
window.displayMonthlyChecklist = displayMonthlyChecklist; // Used by monthly-checklist.html
window.loadAllData = loadAllData;
window.loadDailyDataForToday = loadDailyDataForToday;
window.updateDisplay = updateDisplay; // For index.html
window.updateQuickStats = updateQuickStats; // For all pages
window.toggleSettingsPanel = toggleSettingsPanel; // New global function
window.setDailyGoals = setDailyGoals; // New global function
window.setActiveNavTab = setActiveNavTab; // Make setActiveNavTab globally available
