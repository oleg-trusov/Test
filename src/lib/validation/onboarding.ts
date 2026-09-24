import { z } from 'zod';

export const onboardingSchema = z.object({
  businessName: z.string().trim().min(2).max(120),
  businessType: z.string().trim().min(2).max(80),
  country: z.string().trim().length(2).transform((value) => value.toUpperCase()),
  city: z.string().trim().min(2).max(100),
  address: z.string().trim().min(3).max(180),
  phone: z.string().trim().min(7).max(30),
  timezone: z.string().trim().min(3).max(64),
  currency: z.enum(['CZK', 'EUR', 'USD', 'UAH', 'PLN', 'GBP']),
});

export type OnboardingInput = z.infer<typeof onboardingSchema>;
