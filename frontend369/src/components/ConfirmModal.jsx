// frontend3/src/components/ConfirmModal.jsx
import React from 'react';
import Modal from './Modal'; // Assuming Modal.jsx exists and is a generic modal wrapper

export default function ConfirmModal({ isOpen, onClose, onConfirm, title, message }) {
    return (
        <Modal isOpen={isOpen} onClose={onClose} title={title}>
            <div className="p-4">
                <p className="text-primary mb-6">{message}</p>
                <div className="flex justify-end gap-3">
                    <button
                        onClick={onClose}
                        className="px-4 py-2 rounded-lg text-primary border border-theme hover:bg-tertiary"
                    >
                        Cancelar
                    </button>
                    <button
                        onClick={onConfirm}
                        className="px-4 py-2 rounded-lg bg-red-600 text-white hover:bg-red-700"
                    >
                        Confirmar
                    </button>
                </div>
            </div>
        </Modal>
    );
}
