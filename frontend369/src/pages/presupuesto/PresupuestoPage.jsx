// src/pages/presupuesto/PresupuestoPage.jsx
import React, { useState } from 'react';
import PeriodosPresupuestariosList from './PeriodosPresupuestariosList';
import PartidasPresupuestariasList from './PartidasPresupuestariasList';
import { AnimatePresence, motion } from 'framer-motion';
import HelpButton from '../../components/help/HelpButton';

const PresupuestoPage = () => {
    const [selectedPeriodo, setSelectedPeriodo] = useState(null);

    const handleSelectPeriodo = (periodo) => {
        setSelectedPeriodo(periodo);
    };

    const handleBack = () => {
        setSelectedPeriodo(null);
    };

    const pageVariants = {
        initial: { opacity: 0, x: -50 },
        in: { opacity: 1, x: 0 },
        out: { opacity: 0, x: 50 },
    };

    const pageTransition = {
        type: 'tween',
        ease: 'anticipate',
        duration: 0.5,
    };

    return (
        <div className="relative overflow-hidden">
            <HelpButton moduleKey={selectedPeriodo ? 'partidasPresupuestarias' : 'presupuestos'} />
            <AnimatePresence initial={false} mode="wait">
                {selectedPeriodo ? (
                    <motion.div
                        key="partidas"
                        initial="initial"
                        animate="in"
                        exit="out"
                        variants={pageVariants}
                        transition={pageTransition}
                    >
                        <PartidasPresupuestariasList periodo={selectedPeriodo} onBack={handleBack} />
                    </motion.div>
                ) : (
                    <motion.div
                        key="periodos"
                        initial="initial"
                        animate="in"
                        exit="out"
                        variants={pageVariants}
                        transition={pageTransition}
                    >
                        <PeriodosPresupuestariosList onSelectPeriodo={handleSelectPeriodo} />
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default PresupuestoPage;
