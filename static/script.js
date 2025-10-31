document.addEventListener('DOMContentLoaded', () => {
    
    // These IDs are now guaranteed to match the HTML file.
    const chatForm = document.getElementById('chat-form');
    const messageInput = document.getElementById('message-input');
    const chatMessages = document.getElementById('chat-messages'); // <-- This ID is correct.

    if (!chatForm || !messageInput || !chatMessages) {
        // This error will appear in your browser's developer console (F12) if an ID is wrong.
        console.error("Error: Could not find one or more essential chat elements!");
        return;
    }

    chatForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const message = messageInput.value.trim();
        if (!message) return;

        // 1. Add user message to UI
        addMessage(message, 'user');
        messageInput.value = '';
        
        // Show loading indicator
        const loadingIndicator = addMessage('...', 'bot-loading');

        try {
            // 2. Send to server
            const response = await fetch('/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message: message }),
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            
            // Remove loading indicator
            chatMessages.removeChild(loadingIndicator);

            // 3. Add bot response to UI
            if (data.response) {
                addMessage(data.response, 'bot');
            } else if (data.error) {
                addMessage(`Error: ${data.error}`, 'bot');
            }

        } catch (error) {
            console.error('Error during fetch:', error);
            // Remove loading and show error in chat
            if (loadingIndicator) {
                chatMessages.removeChild(loadingIndicator);
            }
            addMessage(`Sorry, I couldn't connect to the server. ${error.message}`, 'bot');
        }
    });

    function addMessage(text, sender) {
        const messageElement = document.createElement('div');
        messageElement.classList.add('chat-message', `${sender}-message`);
        
        // Sanitize text before setting as innerHTML (simple version)
        // This converts newlines from the bot (like in the timetable) to <br> tags
        messageElement.innerHTML = text.replace(/\n/g, '<br>'); 

        chatMessages.appendChild(messageElement);
        // Scroll to the bottom
        chatMessages.scrollTop = chatMessages.scrollHeight;
        
        return messageElement; // Return for reference (used by loading indicator)
    }
});

