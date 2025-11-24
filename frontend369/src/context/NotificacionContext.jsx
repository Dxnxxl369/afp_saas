// src/context/NotificationContext.jsx
/*import React, { createContext, useState, useContext } from 'react';
import { AnimatePresence, motion } from 'framer-motion';

const NotificationContext = createContext();

export const NotificationProvider = ({ children }) => {
    const [notification, setNotification] = useState(null);

    const showNotification = (message, type = 'success') => {
        setNotification({ message, type });
        setTimeout(() => {
            setNotification(null);
        }, 3000); // La notificación desaparece después de 3 segundos
    };

    return (
        <NotificationContext.Provider value={{ showNotification }}>
            {children}
            <AnimatePresence>
                {notification && (
                    <motion.div
                        initial={{ opacity: 0, y: 50, scale: 0.9 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: 20, scale: 0.9 }}
                        className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50"
                    >
                        <div className={`flex items-center gap-3 px-6 py-3 rounded-lg shadow-lg ${notification.type === 'success' ? 'bg-green-500' : 'bg-red-500'}`}>
                            <p className="font-semibold text-white">{notification.message}</p>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </NotificationContext.Provider>
    );
};

export const useNotification = () => useContext(NotificationContext);*/
// src/context/NotificationContext.jsx
// src/context/NotificacionContext.jsx
import React, { createContext, useState, useContext, useCallback } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { CheckCircle, XCircle } from 'lucide-react';

const NotificacionContext = createContext();

export const NotificationProvider = ({ children }) => {
    const [notification, setNotification] = useState(null);

    const showNotification = useCallback((message, type = 'success') => {
        setNotification({ id: Date.now(), message, type });
        setTimeout(() => {
            setNotification(null);
        }, 3000); // La notificación desaparece después de 3 segundos
    }, []);

    return (
        <NotificacionContext.Provider value={{ showNotification }}>
            {children}
            <div className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50">
                <AnimatePresence>
                    {notification && (
                        <motion.div
                            key={notification.id}
                            initial={{ opacity: 0, y: 50 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, scale: 0.8 }}
                            className={`flex items-center gap-3 px-6 py-3 rounded-lg shadow-lg text-white ${notification.type === 'success' ? 'bg-green-500' : 'bg-red-500'}`}
                        >
                            {notification.type === 'success' ? <CheckCircle size={20} /> : <XCircle size={20} />}
                            <p className="font-semibold">{notification.message}</p>
                        </motion.div>
                    )}
                </AnimatePresence>
            </div>
        </NotificacionContext.Provider>
    );
};

export const useNotification = () => useContext(NotificacionContext);