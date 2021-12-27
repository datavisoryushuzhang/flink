/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.flink.util;

import org.slf4j.MDC;

/** An util class to store tenant name in local thread. */
public class TenantContext {
    public static final String DEFAULT_TENANT_IDENTIFIER = "admin";
    private static final String TENANT_MDC_KEY = "tenant";

    private static final ThreadLocal<String> TENANT_IDENTIFIER = new ThreadLocal<>();

    public static String getTenant() {
        return TENANT_IDENTIFIER.get();
    }

    public static void setTenant(String tenantIdentifier) {
        TENANT_IDENTIFIER.set(tenantIdentifier);
        MDC.put(TENANT_MDC_KEY, tenantIdentifier);
    }

    public static void reset() {
        TENANT_IDENTIFIER.remove();
        MDC.clear();
    }

    public static void setToAdminTenant() {
        setTenant(DEFAULT_TENANT_IDENTIFIER);
        MDC.put(TENANT_MDC_KEY, DEFAULT_TENANT_IDENTIFIER);
    }
}
