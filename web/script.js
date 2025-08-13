class LearnToEarnApp {
    constructor() {
        this.connected = false;
        this.currentModule = null;
        this.currentQuiz = null;
        this.selectedAnswer = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadDashboard();
        this.loadModules();
    }

    setupEventListeners() {
        document.getElementById('connectWallet').addEventListener('click', () => this.connectWallet());
        document.getElementById('createModuleForm').addEventListener('submit', (e) => this.createModule(e));
        document.getElementById('completeModule').addEventListener('click', () => this.completeModule());
        document.getElementById('claimReward').addEventListener('click', () => this.claimReward());
        document.getElementById('fundForm').addEventListener('submit', (e) => this.fundContract(e));
    }

    showSection(sectionId) {
        document.querySelectorAll('.section').forEach(section => {
            section.classList.remove('active');
        });
        document.getElementById(sectionId).classList.add('active');
        
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        event.target.classList.add('active');

        if (sectionId === 'profile') {
            this.loadUserProfile();
        }
    }

    async connectWallet() {
        try {
            const walletStatus = document.getElementById('walletStatus');
            const connectBtn = document.getElementById('connectWallet');
            
            walletStatus.textContent = 'Connecting...';
            
            setTimeout(() => {
                this.connected = true;
                walletStatus.textContent = 'Connected: SP1234...ABCD';
                connectBtn.textContent = 'Disconnect';
                connectBtn.onclick = () => this.disconnectWallet();
                this.showNotification('Wallet connected successfully!', 'success');
            }, 1000);
        } catch (error) {
            this.showNotification('Failed to connect wallet', 'error');
        }
    }

    disconnectWallet() {
        this.connected = false;
        document.getElementById('walletStatus').textContent = 'Not connected';
        const connectBtn = document.getElementById('connectWallet');
        connectBtn.textContent = 'Connect Wallet';
        connectBtn.onclick = () => this.connectWallet();
        this.showNotification('Wallet disconnected', 'info');
    }

    async loadDashboard() {
        const stats = await this.mockContractCall('getContractStats');
        
        document.getElementById('totalModules').textContent = stats.totalModules;
        document.getElementById('contractBalance').textContent = `${stats.contractBalance} STX`;
        document.getElementById('totalRewards').textContent = `${stats.totalRewards} STX`;
        document.getElementById('platformFee').textContent = `${stats.platformFee}%`;
    }

    async loadModules() {
        const modulesList = document.getElementById('modulesList');
        modulesList.innerHTML = '<div class="loading">Loading modules...</div>';
        
        try {
            const modules = await this.mockContractCall('getModules');
            
            if (modules.length === 0) {
                modulesList.innerHTML = '<div class="loading">No modules available</div>';
                return;
            }
            
            modulesList.innerHTML = modules.map(module => `
                <div class="module-card" onclick="app.openModule(${module.id})">
                    <h3 class="module-title">${module.title}</h3>
                    <p class="module-description">${module.description}</p>
                    <div class="module-meta">
                        <span>Reward: ${module.reward} STX</span>
                        <span class="difficulty-badge difficulty-${module.difficulty}">
                            ${this.getDifficultyLabel(module.difficulty)}
                        </span>
                    </div>
                </div>
            `).join('');
        } catch (error) {
            modulesList.innerHTML = '<div class="loading">Error loading modules</div>';
        }
    }

    async createModule(event) {
        event.preventDefault();
        
        if (!this.connected) {
            this.showNotification('Please connect your wallet first', 'error');
            return;
        }
        
        const formData = new FormData(event.target);
        const moduleData = {
            title: formData.get('moduleTitle'),
            description: formData.get('moduleDescription'),
            reward: parseFloat(formData.get('rewardAmount')),
            difficulty: parseInt(formData.get('difficultyLevel'))
        };
        
        try {
            await this.mockContractCall('createModule', moduleData);
            this.showNotification('Module created successfully!', 'success');
            this.closeModal('createModuleModal');
            event.target.reset();
            this.loadModules();
            this.loadDashboard();
        } catch (error) {
            this.showNotification('Failed to create module', 'error');
        }
    }

    async openModule(moduleId) {
        const module = await this.mockContractCall('getModule', { id: moduleId });
        const quiz = await this.mockContractCall('getQuiz', { moduleId });
        
        this.currentModule = module;
        this.currentQuiz = quiz;
        
        document.getElementById('modalModuleTitle').textContent = module.title;
        document.getElementById('modalModuleDescription').textContent = module.description;
        document.getElementById('modalReward').textContent = module.reward;
        document.getElementById('modalDifficulty').textContent = this.getDifficultyLabel(module.difficulty);
        
        if (quiz) {
            document.getElementById('quizContent').innerHTML = `
                <div class="quiz-question">${quiz.question}</div>
                <div class="quiz-options">
                    ${quiz.options.map((option, index) => `
                        <div class="quiz-option" onclick="app.selectAnswer(${index + 1})">
                            ${index + 1}. ${option}
                        </div>
                    `).join('')}
                </div>
            `;
        }
        
        this.updateModuleButtons(module);
        this.showModal('moduleModal');
    }

    selectAnswer(answer) {
        this.selectedAnswer = answer;
        
        document.querySelectorAll('.quiz-option').forEach(option => {
            option.classList.remove('selected');
        });
        
        document.querySelectorAll('.quiz-option')[answer - 1].classList.add('selected');
    }

    async completeModule() {
        if (!this.connected) {
            this.showNotification('Please connect your wallet first', 'error');
            return;
        }
        
        if (!this.selectedAnswer) {
            this.showNotification('Please select an answer first', 'error');
            return;
        }
        
        try {
            const score = this.selectedAnswer === this.currentQuiz.correctAnswer ? 100 : 0;
            await this.mockContractCall('completeModule', { 
                moduleId: this.currentModule.id, 
                score: score 
            });
            
            if (score >= 70) {
                this.showNotification('Module completed successfully!', 'success');
                this.updateModuleButtons(this.currentModule, true);
            } else {
                this.showNotification('Quiz failed. Try again!', 'error');
            }
        } catch (error) {
            this.showNotification('Failed to complete module', 'error');
        }
    }

    async claimReward() {
        if (!this.connected) {
            this.showNotification('Please connect your wallet first', 'error');
            return;
        }
        
        try {
            const reward = await this.mockContractCall('claimReward', { 
                moduleId: this.currentModule.id 
            });
            
            this.showNotification(`Reward claimed: ${reward} STX!`, 'success');
            this.closeModal('moduleModal');
            this.loadDashboard();
        } catch (error) {
            this.showNotification('Failed to claim reward', 'error');
        }
    }

    async fundContract(event) {
        event.preventDefault();
        
        if (!this.connected) {
            this.showNotification('Please connect your wallet first', 'error');
            return;
        }
        
        const amount = parseFloat(document.getElementById('fundAmount').value);
        
        try {
            await this.mockContractCall('fundContract', { amount });
            this.showNotification(`Contract funded with ${amount} STX!`, 'success');
            this.closeModal('fundModal');
            this.loadDashboard();
        } catch (error) {
            this.showNotification('Failed to fund contract', 'error');
        }
    }

    async loadUserProfile() {
        const profile = await this.mockContractCall('getUserProfile');
        
        document.getElementById('userLevel').textContent = profile.level;
        document.getElementById('userExperience').textContent = profile.experience;
        document.getElementById('userStreak').textContent = profile.streak;
        document.getElementById('completedModules').textContent = profile.completedModules;
        document.getElementById('totalEarned').textContent = `${profile.totalEarned} STX`;
        
        const userModules = document.getElementById('userModules');
        userModules.innerHTML = profile.modules.map(module => `
            <div class="user-module-card ${module.completed ? 'completed' : ''}">
                <h4>${module.title}</h4>
                <p>Score: ${module.score}%</p>
                <p>Status: ${module.completed ? 'Completed' : 'In Progress'}</p>
                ${module.rewardClaimed ? '<p>✅ Reward Claimed</p>' : ''}
            </div>
        `).join('');
    }

    updateModuleButtons(module, completed = false) {
        const completeBtn = document.getElementById('completeModule');
        const claimBtn = document.getElementById('claimReward');
        
        if (completed) {
            completeBtn.style.display = 'none';
            claimBtn.style.display = 'block';
        } else {
            completeBtn.style.display = 'block';
            claimBtn.style.display = 'none';
        }
    }

    getDifficultyLabel(difficulty) {
        const labels = {
            1: 'Beginner',
            2: 'Easy',
            3: 'Medium',
            4: 'Hard',
            5: 'Expert'
        };
        return labels[difficulty] || 'Unknown';
    }

    showModal(modalId) {
        document.getElementById(modalId).style.display = 'block';
    }

    closeModal(modalId) {
        document.getElementById(modalId).style.display = 'none';
    }

    showCreateModule() {
        if (!this.connected) {
            this.showNotification('Please connect your wallet first', 'error');
            return;
        }
        this.showModal('createModuleModal');
    }

    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 1rem 2rem;
            border-radius: 0.5rem;
            color: white;
            font-weight: bold;
            z-index: 10000;
            animation: slideIn 0.3s ease-out;
        `;
        
        const colors = {
            success: '#10b981',
            error: '#ef4444',
            info: '#3b82f6'
        };
        
        notification.style.backgroundColor = colors[type] || colors.info;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.remove();
        }, 3000);
    }

    async mockContractCall(method, data = {}) {
        return new Promise((resolve) => {
            setTimeout(() => {
                switch (method) {
                    case 'getContractStats':
                        resolve({
                            totalModules: 5,
                            contractBalance: 1000,
                            totalRewards: 250,
                            platformFee: 5
                        });
                        break;
                    
                    case 'getModules':
                        resolve([
                            {
                                id: 1,
                                title: 'Introduction to Blockchain',
                                description: 'Learn the basics of blockchain technology',
                                reward: 50,
                                difficulty: 1
                            },
                            {
                                id: 2,
                                title: 'Smart Contracts 101',
                                description: 'Understanding smart contracts and their applications',
                                reward: 75,
                                difficulty: 2
                            },
                            {
                                id: 3,
                                title: 'DeFi Fundamentals',
                                description: 'Explore decentralized finance concepts',
                                reward: 100,
                                difficulty: 3
                            }
                        ]);
                        break;
                    
                    case 'getModule':
                        resolve({
                            id: data.id,
                            title: 'Introduction to Blockchain',
                            description: 'Learn the basics of blockchain technology and how it works',
                            reward: 50,
                            difficulty: 1
                        });
                        break;
                    
                    case 'getQuiz':
                        resolve({
                            question: 'What is the main characteristic of blockchain?',
                            options: [
                                'Centralized control',
                                'Immutable ledger',
                                'Fast transactions',
                                'Low fees'
                            ],
                            correctAnswer: 2
                        });
                        break;
                    
                    case 'getUserProfile':
                        resolve({
                            level: 2,
                            experience: 125,
                            streak: 5,
                            completedModules: 3,
                            totalEarned: 225,
                            modules: [
                                {
                                    title: 'Introduction to Blockchain',
                                    score: 85,
                                    completed: true,
                                    rewardClaimed: true
                                },
                                {
                                    title: 'Smart Contracts 101',
                                    score: 92,
                                    completed: true,
                                    rewardClaimed: true
                                }
                            ]
                        });
                        break;
                    
                    case 'completeModule':
                        resolve(true);
                        break;
                    
                    case 'claimReward':
                        resolve(data.reward || 50);
                        break;
                    
                    case 'createModule':
                        resolve(true);
                        break;
                    
                    case 'fundContract':
                        resolve(true);
                        break;
                    
                    default:
                        resolve(null);
                }
            }, 500);
        });
    }
}

const app = new LearnToEarnApp();

window.showSection = (sectionId) => app.showSection(sectionId);
window.showCreateModule = () => app.showCreateModule();
window.closeModal = (modalId) => app.closeModal(modalId);

const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
`;
document.head.appendChild(style);

window.onclick = function(event) {
    if (event.target.classList.contains('modal')) {
        event.target.style.display = 'none';
    }
}
