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
    displayMonthlyChecklist(currentYear, currentMonth);
  }
  
  // Initialize settings panel values
  loadDailyGoals();

  // Set interval for saving daily data if localStorage is available
  if (isLocalStorageAvailable) {
    setInterval(saveDailyDataForToday, 30000); // Save current day's data every 30 seconds
  }
});

// Utility function to format date as YYYY-MM-DD
function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Show notification function
function showNotification(message, type) {
  const notification = document.createElement('div');
  notification.classList.add('notification', type);
  notification.textContent = message;
  document.body.appendChild(notification);

  // Trigger reflow to enable transition
  notification.offsetWidth; 
  notification.classList.add('show');

  setTimeout(() => {
    notification.classList.remove('show');
    notification.addEventListener('transitionend', () => {
      notification.remove();
    }, { once: true });
  }, 3000); // Notification disappears after 3 seconds
}

// Save and Load Functions
function saveDailyDataForToday() {
  const todayKey = formatDate(new Date());
  allDailyData[todayKey] = { ...dailyData }; // Save a copy
  if (isLocalStorageAvailable) {
    localStorage.setItem('allDailyData', JSON.stringify(allDailyData));
  }
  updateQuickStats(); // Update quick stats after saving
  // console.log(`Daily data for ${todayKey} saved.`, dailyData); // For debugging
}

function loadAllData() {
  if (isLocalStorageAvailable) {
    const storedData = localStorage.getItem('allDailyData');
    if (storedData) {
      allDailyData = JSON.parse(storedData);
    }
  }
  // console.log("All historical data loaded:", allDailyData); // For debugging
}

function loadDailyDataForToday() {
  const todayKey = formatDate(new Date());
  if (allDailyData[todayKey]) {
    dailyData = { ...allDailyData[todayKey] }; // Load data for today
  } else {
    // If no data for today, initialize with default goals and empty meals
    dailyData = {
      consumed: { calories: 0, protein: 0, carbs: 0, fats: 0 },
      goals: { ...dailyData.goals }, // Retain previously set goals or defaults
      meals: []
    };
    allDailyData[todayKey] = { ...dailyData }; // Add empty entry for today
  }
  // console.log("Daily data for today loaded:", dailyData); // For debugging
}

function loadDailyGoals() {
  // Load goals from dailyData into settings panel
  document.getElementById('goalCalories').value = dailyData.goals.calories;
  document.getElementById('goalProtein').value = dailyData.goals.protein;
  document.getElementById('goalCarbs').value = dailyData.goals.carbs;
  document.getElementById('goalFats').value = dailyData.goals.fats;
}

function setDailyGoals() {
  const calories = parseInt(document.getElementById('goalCalories').value) || 0;
  const protein = parseInt(document.getElementById('goalProtein').value) || 0;
  const carbs = parseInt(document.getElementById('goalCarbs').value) || 0;
  const fats = parseInt(document.getElementById('goalFats').value) || 0;

  if (calories <= 0 || protein <= 0 || carbs <= 0 || fats <= 0) {
    showNotification('Please enter valid positive numbers for all goals.', 'error');
    return;
  }

  dailyData.goals = { calories, protein, carbs, fats };
  saveDailyDataForToday(); // Save updated goals
  updateDisplay(); // Update display with new goals
  updateQuickStats(); // Update quick stats with new goals
  showNotification('Daily goals updated successfully!', 'success');
  toggleSettingsPanel(); // Hide settings panel after saving
}

// Update Display (index.html specific)
function updateDisplay() {
  if (!document.getElementById('tracker')) return; // Only run if on index.html

  document.getElementById('caloriesConsumed').textContent = dailyData.consumed.calories;
  document.getElementById('caloriesGoal').textContent = dailyData.goals.calories;
  document.getElementById('proteinConsumed').textContent = dailyData.consumed.protein;
  document.getElementById('proteinGoal').textContent = dailyData.goals.protein;
  document.getElementById('carbsConsumed').textContent = dailyData.consumed.carbs;
  document.getElementById('carbsGoal').textContent = dailyData.goals.carbs;
  document.getElementById('fatsConsumed').textContent = dailyData.consumed.fats;
  document.getElementById('fatsGoal').textContent = dailyData.goals.fats;

  const caloriePercentage = dailyData.goals.calories > 0
    ? (dailyData.consumed.calories / dailyData.goals.calories) * 100
    : 0;
  const progressBar = document.getElementById('calorieProgressBar');
  if (progressBar) {
    progressBar.style.width = `${Math.min(caloriePercentage, 100)}%`;
    if (caloriePercentage >= 100) {
        progressBar.style.backgroundColor = '#ffc107'; // Yellow if goal met/exceeded
    } else {
        progressBar.style.backgroundColor = 'white'; // White otherwise
    }
  }

  const mealsList = document.getElementById('mealsList');
  if (mealsList) {
    mealsList.innerHTML = ''; // Clear previous list
    dailyData.meals.forEach((meal, index) => {
      const mealItem = document.createElement('div');
      mealItem.classList.add('meal-item');
      mealItem.innerHTML = `
        <div class="meal-info">
          <h4>${meal.name}</h4>
          <p class="meal-details">${meal.calories} kcal | ${meal.protein}g P | ${meal.carbs}g C | ${meal.fats}g F</p>
        </div>
        <button class="delete-btn" onclick="deleteFood(${index})">Delete</button>
      `;
      mealsList.appendChild(mealItem);
    });
  }
}

// Add Food
function addFood() {
  const foodName = document.getElementById('foodName').value;
  const calories = parseInt(document.getElementById('calories').value);
  const protein = parseInt(document.getElementById('protein').value);
  const carbs = parseInt(document.getElementById('carbs').value);
  const fats = parseInt(document.getElementById('fats').value);

  if (!foodName || isNaN(calories) || isNaN(protein) || isNaN(carbs) || isNaN(fats) || calories < 0 || protein < 0 || carbs < 0 || fats < 0) {
    showNotification('Please fill in all food details with valid positive numbers.', 'error');
    return;
  }

  dailyData.meals.push({ name: foodName, calories, protein, carbs, fats });
  dailyData.consumed.calories += calories;
  dailyData.consumed.protein += protein;
  dailyData.consumed.carbs += carbs;
  dailyData.consumed.fats += fats;

  saveDailyDataForToday();
  updateDisplay();

  // Clear form
  document.getElementById('foodName').value = '';
  document.getElementById('calories').value = '';
  document.getElementById('protein').value = '';
  document.getElementById('carbs').value = '';
  document.getElementById('fats').value = '';

  showNotification('Food added successfully!', 'success');
}

// Delete Food
function deleteFood(index) {
  const meal = dailyData.meals[index];
  dailyData.consumed.calories -= meal.calories;
  dailyData.consumed.protein -= meal.protein;
  dailyData.consumed.carbs -= meal.carbs;
  dailyData.consumed.fats -= meal.fats;

  dailyData.meals.splice(index, 1); // Remove from array

  saveDailyDataForToday();
  updateDisplay();
  showNotification('Food item deleted.', 'info');
}

// Clear All Meals
function clearAllMeals() {
  if (confirm('Are you sure you want to clear all meals for today?')) {
    dailyData.meals = [];
    dailyData.consumed = { calories: 0, protein: 0, carbs: 0, fats: 0 };
    saveDailyDataForToday();
    updateDisplay();
    showNotification('All meals cleared for today.', 'info');
  }
}

// Sidebar Functions
function toggleSidebar() {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('overlay');
  sidebar.classList.toggle('open');
  overlay.classList.toggle('active');
}

// Settings Panel Functions
function toggleSettingsPanel() {
  const settingsPanel = document.getElementById('settingsPanel');
  if (settingsPanel) {
    settingsPanel.style.display = settingsPanel.style.display === 'block' ? 'none' : 'block';
    if (settingsPanel.style.display === 'block') {
      loadDailyGoals(); // Load current goals when panel opens
    }
  }
}

// Quick Stats Update (for all pages)
function updateQuickStats() {
  const calorieProgressElement = document.getElementById('calorieProgress');
  const streakDaysElement = document.getElementById('streakDays');

  if (calorieProgressElement) {
    const todayKey = formatDate(new Date());
    const todayData = allDailyData[todayKey];
    
    let percentage = 0;
    if (todayData && todayData.goals.calories > 0) {
      percentage = Math.round((todayData.consumed.calories / todayData.goals.calories) * 100);
    }
    calorieProgressElement.textContent = `${percentage}%`;
  }

  if (streakDaysElement) {
    let streak = 0;
    let currentDate = new Date();
    currentDate.setHours(0, 0, 0, 0); // Normalize to start of day

    while (true) {
      const dateKey = formatDate(currentDate);
      const dayData = allDailyData[dateKey];

      // Check if data exists for the day and calorie goal was met or exceeded
      if (dayData && dayData.consumed.calories >= dayData.goals.calories) {
        streak++;
        currentDate.setDate(currentDate.getDate() - 1); // Go to previous day
      } else {
        break; // Streak broken or no data
      }
    }
    streakDaysElement.textContent = streak;
  }
}

// Monthly Checklist Functions
function displayMonthlyChecklist(year, month) {
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
    const emptyDay = document.createElement('div');
    emptyDay.classList.add('day-checkbox', 'empty');
    checklistGrid.appendChild(emptyDay);
  }

  // Add days of the month
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month, day);
    const dateKey = formatDate(date);
    const dayData = allDailyData[dateKey];
    const isGoalMet = dayData && dayData.consumed.calories >= dayData.goals.calories;
    const hasData = !!dayData; // Check if any data exists for the day

    const dayCheckboxDiv = document.createElement('div');
    dayCheckboxDiv.classList.add('day-checkbox');
    if (hasData) {
      dayCheckboxDiv.classList.add('has-data');
    }

    // Use a simple div that looks like a checkbox for display, make it clickable
    dayCheckboxDiv.innerHTML = `
      <input type="checkbox" id="day-${dateKey}" ${isGoalMet ? 'checked' : ''} disabled>
      <label for="day-${dateKey}">
        ${day}
        <span>${isGoalMet ? 'Goal Met' : (hasData ? 'Not Met' : 'No Data')}</span>
      </label>
    `;
    
    // Add click listener to navigate to day-result.html
    dayCheckboxDiv.querySelector('label').addEventListener('click', () => {
        window.location.href = `day-result.html?date=${dateKey}`;
    });

    checklistGrid.appendChild(dayCheckboxDiv);
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
  displayMonthlyChecklist(currentYear, currentMonth);
}


// Day Result Page Functions
function displayDayResult(dateKey) {
  const dayData = allDailyData[dateKey];
  const resultDateEl = document.getElementById('resultDate');
  const resultCaloriesEl = document.getElementById('resultCalories');
  const resultProteinEl = document.getElementById('resultProtein');
  const resultCarbsEl = document.getElementById('resultCarbs');
  const resultFatsEl = document.getElementById('resultFats');
  const resultMealsListEl = document.getElementById('resultMealsList');
  const aiSuggestedMealsEl = document.getElementById('aiSuggestedMeals');
  const navDayChosenEl = document.getElementById('navDayChosen');

  if (navDayChosenEl) {
    navDayChosenEl.textContent = new Date(dateKey).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    navDayChosenEl.style.display = 'block';
    // Remove active class from other tabs
    document.getElementById('navDailyTracker').classList.remove('active');
    document.getElementById('navMonthlyProgress').classList.remove('active');
    document.getElementById('navSubscriptions').classList.remove('active');
    // Add active class to this dynamically created tab
    navDayChosenEl.classList.add('active');
  }


  if (dayData) {
    resultDateEl.textContent = new Date(dateKey).toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
    resultCaloriesEl.textContent = `${dayData.consumed.calories} / ${dayData.goals.calories} kcal`;
    resultProteinEl.textContent = `${dayData.consumed.protein} / ${dayData.goals.protein}g`;
    resultCarbsEl.textContent = `${dayData.consumed.carbs} / ${dayData.goals.carbs}g`;
    resultFatsEl.textContent = `${dayData.consumed.fats} / ${dayData.goals.fats}g`;

    resultMealsListEl.innerHTML = '<h3>Meals Consumed:</h3>';
    if (dayData.meals.length > 0) {
      dayData.meals.forEach(meal => {
        const mealItem = document.createElement('div');
        mealItem.classList.add('result-meal-item');
        mealItem.innerHTML = `
          <h4>${meal.name}</h4>
          <p class="result-meal-details">${meal.calories} kcal | ${meal.protein}g P | ${meal.carbs}g C | ${meal.fats}g F</p>
        `;
        resultMealsListEl.appendChild(mealItem);
      });
    } else {
      resultMealsListEl.innerHTML += '<p>No meals recorded for this day.</p>';
    }

    // A.I Suggested Meals based on goals and consumed for the day
    let suggestions = [];
    if (dayData.consumed.calories < dayData.goals.calories * 0.9) { // If significantly under calories
      suggestions.push("Consider a small, balanced snack.");
    }
    if (dayData.consumed.protein < dayData.goals.protein * 0.8) {
      suggestions.push("Add a protein-rich food like chicken breast or a protein shake.");
    }
    if (dayData.consumed.carbs < dayData.goals.carbs * 0.8) {
      suggestions.push("Include some whole grains or fruits.");
    }
    if (dayData.consumed.fats < dayData.goals.fats * 0.8) {
      suggestions.push("Add healthy fats like avocado or nuts.");
    }

    if (suggestions.length > 0) {
      aiSuggestedMealsEl.textContent = suggestions.join(' ');
    } else if (dayData.consumed.calories >= dayData.goals.calories && dayData.consumed.protein >= dayData.goals.protein && dayData.consumed.carbs >= dayData.goals.carbs && dayData.consumed.fats >= dayData.goals.fats) {
        aiSuggestedMealsEl.textContent = `Great job! You met all your macro goals today.`;
    }
    else {
      aiSuggestedMealsEl.textContent = `Looks like you're on track! Keep it up.`;
    }

  } else {
    // Handle case where no data exists for the date
    resultDateEl.textContent = 'No Data Available';
    resultCaloriesEl.textContent = '0 kcal';
    resultProteinEl.textContent = '0g';
    resultCarbsEl.textContent = '0g';
    resultFatsEl.textContent = '0g';
    resultMealsListEl.innerHTML = '<p>No meals recorded for this day.</p>';
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

// Set active navigation tab in both sidebar and header nav-tabs
function setActiveNavTab() {
  const path = window.location.pathname;
  const page = path.split('/').pop(); // Get filename (e.g., "index.html")

  // Handle sidebar links
  document.querySelectorAll('.sidebar-menu a').forEach(link => {
    link.classList.remove('active');
    if (link.getAttribute('href') === page) {
      link.classList.add('active');
    }
  });

  // Handle header nav-tabs
  document.querySelectorAll('.nav-tabs .nav-tab').forEach(tab => {
    tab.classList.remove('active');
    // Special handling for day-result.html which has a dynamic tab
    if (page === 'day-result.html') {
      document.getElementById('navDayChosen').classList.add('active');
    } else if (tab.getAttribute('href') === page) {
      tab.classList.add('active');
    }
  });

  // Hide the dynamic "Day Chosen" tab by default, it will be shown by displayDayResult if needed
  const navDayChosenEl = document.getElementById('navDayChosen');
  if (navDayChosenEl && page !== 'day-result.html') {
    navDayChosenEl.style.display = 'none';
  }
}


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
window.setActiveNavTab = setActiveNavTab; // Make global for other scripts
window.showNotification = showNotification; // Make global for other scripts