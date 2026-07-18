const express = require('express');
const supabase = require('../db');

const router = express.Router();

router.get('/', async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('rabt_sectors')
            .select('*')
            .eq('is_operational', true);

        if (error) return res.status(500).json({ error: error.message });

        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/:sectorCode', async (req, res) => {
    const { sectorCode } = req.params;

    try {
        const { data, error } = await supabase
            .from('rabt_sectors')
            .select('*')
            .eq('sector_code', sectorCode)
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
